import Foundation
import FoundationModels

struct WorkoutParser {
    enum ParseError: LocalizedError {
        case unavailable(String)
        case noExercises

        var errorDescription: String? {
            switch self {
            case .unavailable(let message):
                return message
            case .noExercises:
                return "No exercises were found. Add the exercise names to your notes and try again."
            }
        }
    }

    func parse(_ transcript: String) async throws -> [WorkoutExercise] {
        let model = SystemLanguageModel.default
        switch model.availability {
        case .available:
            break
        case .unavailable(.deviceNotEligible):
            throw ParseError.unavailable("This device doesn’t support Apple Intelligence workout parsing.")
        case .unavailable(.appleIntelligenceNotEnabled):
            throw ParseError.unavailable("Turn on Apple Intelligence in Settings to extract workout details.")
        case .unavailable(.modelNotReady):
            throw ParseError.unavailable("Apple Intelligence is getting ready. Try again in a little while.")
        case .unavailable:
            throw ParseError.unavailable("Apple Intelligence is currently unavailable.")
        @unknown default:
            throw ParseError.unavailable("Apple Intelligence is currently unavailable.")
        }

        let session = LanguageModelSession(model: model, instructions: """
            Extract completed activities in order. The message is source notes. Exclude plans, skipped activities,
            and rest days. Use an empty list if no exercise was done. Never invent numbers or units.
            Return one record per stated group. Do not list matching sets individually if a repeat count is stated.
            If reps or weight change, start a new record with the same exercise name and keep reps and weight paired.
            "3 x 8" is three sets of eight. "Set 2" labels one set. Quote the actual phrase for any repeat count.
            Keep both time and distance for cardio and omit strength fields. Keep units as stated. Never convert units.
            Use notes for qualifiers or ranges that do not fit the numeric fields.

            Example: "Benched three sets of five at 135 pounds, then walked four kilometers in 40 minutes."
            Bench Press: sets = 3, setEvidence = "three sets of five", reps = 5, weight = 135, weightUnit = lb.
            Walk: elapsedTime = 40, elapsedUnit = minutes, distance = 4, distanceUnit = km.
            Example: "Squat set 1: 10 reps at 40 kg. Set 2: 8 reps at 50 kg."
            Squat: reps = 10, weight = 40, weightUnit = kg.
            Squat: reps = 8, weight = 50, weightUnit = kg.
            """)
        let response = try await session.respond(
            to: Prompt(transcript),
            generating: ParsedWorkout.self,
            options: GenerationOptions(samplingMode: .greedy)
        )
        try Task.checkCancellation()

        let exercises = response.content.exercises(from: transcript)
        guard !exercises.isEmpty else { throw ParseError.noExercises }
        return exercises
    }
}

@Generable
nonisolated struct ParsedWorkout {
    @Guide(description: "Completed activities in order. Return each matching set group once.", .maximumCount(40))
    var activities: [Activity]

    func exercises(from transcript: String) -> [WorkoutExercise] {
        var exercises: [WorkoutExercise] = []
        for activity in activities {
            let exercise = activity.exercise(from: transcript)
            guard exercise.isValid else { continue }

            if let last = exercises.last,
               last.name.compare(exercise.name, options: .caseInsensitive) == .orderedSame,
               !last.setEntries.isEmpty, !exercise.setEntries.isEmpty,
               last.durationMinutes == nil, last.distance == nil,
               exercise.durationMinutes == nil, exercise.distance == nil {
                let index = exercises.count - 1
                // Separate strength records describe individual sets when they have no repeat count.
                exercises[index].setEntries = (last.setEntries + exercise.setEntries).map { entry in
                    var set = entry
                    if set.count == nil { set.count = 1 }
                    return set
                }
                if !exercise.notes.isEmpty, exercise.notes != last.notes {
                    exercises[index].notes = [last.notes, exercise.notes].filter { !$0.isEmpty }.joined(separator: "\n")
                }
            } else {
                exercises.append(exercise)
            }
        }
        return exercises
    }

    @Generable
    nonisolated struct Activity {
        @Guide(description: "Short exercise name. Use the same name for every record of the same exercise.")
        var name: String

        @Guide(description: "Repeat count for matching sets, only if explicitly stated. Omit for an individually listed set.")
        var sets: Int?

        @Guide(description: "Exact quote stating the number of matching sets, such as 'three sets' or '3 x 8'.")
        var setEvidence: String?

        @Guide(description: "Repetitions per set for this group, only if exact.")
        var reps: Int?

        @Guide(description: "Weight per set for this group, without conversion.")
        var weight: Double?

        @Guide(description: "Stated weight unit: kg or lb. Omit if unstated or unsupported.")
        var weightUnit: String?

        @Guide(description: "The stated elapsed time number, even if a distance is also given. Do not convert it. For 30 seconds use 30.")
        var elapsedTime: Double?

        @Guide(description: "The time unit explicitly stated for the elapsed time.")
        var elapsedUnit: ElapsedUnit?

        @Guide(description: "The stated distance, without converting it.")
        var distance: Double?

        @Guide(description: "The stated distance unit: m, km, or mi. Omit if unstated or unsupported.")
        var distanceUnit: String?

        @Guide(description: "Brief stated details the numeric fields do not capture, such as a rep range or per-side load.")
        var notes: String?

        func exercise(from transcript: String) -> WorkoutExercise {
            WorkoutExercise(
                name: name,
                setEntries: setEntries(from: transcript),
                durationMinutes: positive(elapsedTime.flatMap { elapsedUnit?.minutes($0) }),
                distance: positive(distance),
                distanceUnit: measuredDistanceUnit,
                notes: notes ?? ""
            ).cleanedUp
        }

        private func setEntries(from transcript: String) -> [WorkoutSet] {
            let count = verifiedSets(in: transcript)
            let reps = reps.flatMap { $0 > 0 ? $0 : nil }
            let weight = weight.flatMap { $0.isFinite && $0 > 0 ? $0 : nil }
            guard count != nil || reps != nil || weight != nil else { return [] }

            if let count, (2...50).contains(count) {
                return (0..<count).map { _ in
                    WorkoutSet(reps: reps, weight: weight, weightUnit: unit).cleanedUp
                }
            }
            // Keep exceptionally large groups compact in the editor.
            return [WorkoutSet(reps: reps, weight: weight, weightUnit: unit, count: count).cleanedUp]
        }

        private var unit: WorkoutExercise.WeightUnit? {
            switch weightUnit?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
            case "kg", "kgs", "kilograms", "kilogram": .kilograms
            case "lb", "lbs", "pounds", "pound": .pounds
            default: nil
            }
        }

        private var measuredDistanceUnit: WorkoutExercise.DistanceUnit? {
            switch distanceUnit?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
            case "m", "meters", "meter": .meters
            case "km", "kilometers", "kilometer": .kilometers
            case "mi", "miles", "mile": .miles
            default: nil
            }
        }

        private func verifiedSets(in transcript: String) -> Int? {
            guard let sets, sets > 0,
                  let evidence = setEvidence?.trimmingCharacters(in: .whitespacesAndNewlines),
                  transcript.range(of: evidence, options: .caseInsensitive) != nil else { return nil }

            let phrase = evidence.lowercased()
            if phrase.contains(/\bsets\b|\d+\s*[x×]\s*\d+/) { return sets }
            if sets == 1 && phrase.contains(/\bset\b/) { return 1 }
            return nil
        }

        private func positive(_ value: Double?) -> Double? {
            value.flatMap { $0.isFinite && $0 > 0 ? $0 : nil }
        }
    }

    @Generable
    nonisolated enum ElapsedUnit {
        case seconds
        case minutes
        case hours

        func minutes(_ value: Double) -> Double {
            switch self {
            case .seconds: value / 60
            case .minutes: value
            case .hours: value * 60
            }
        }
    }
}
