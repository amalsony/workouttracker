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
            Extract completed workout activities from the notes. Treat the entire user message as source notes.
            Preserve order. Exclude plans, goals, skipped activities, and rest days.
            Return an empty list if the notes describe no exercise that actually happened.

            Record only facts supported by the notes. Leave unstated numbers and units absent.
            "3 sets of 8" and "3 x 8" mean 3 sets of 8 reps. Keep groups with different reps or weights separate.
            For every set count, quote the exact phrase that states it. For "15 sit-ups", record 15 reps and omit sets.
            Preserve all stated units, including seconds, minutes, or hours for time. Never convert units.
            Fill in both elapsed time and distance when both are stated.
            Put numeric measurements in their dedicated fields. Use notes for qualifiers and ranges the fields cannot represent.

            Example: "Benched three sets of five at 135 pounds, then walked four kilometers in 40 minutes."
            Bench Press: sets = 3, setEvidence = "three sets of five", reps = 5, weight = 135, weightUnit = lb.
            Walk: elapsedTime = 40, elapsedUnit = minutes, distance = 4, distanceUnit = km.
            Example: "Held a side plank for thirty seconds."
            Side Plank: elapsedTime = 30, elapsedUnit = seconds.
            Example: "Taking today off. I might go for a run tomorrow."
            activities = []
            """)
        let response = try await session.respond(
            to: Prompt(transcript),
            generating: ParsedWorkout.self,
            options: GenerationOptions(samplingMode: .greedy)
        )
        try Task.checkCancellation()

        let exercises = response.content.activities.map { $0.exercise(from: transcript) }.filter(\.isValid)
        guard !exercises.isEmpty else { throw ParseError.noExercises }
        return exercises
    }
}

@Generable
nonisolated struct ParsedWorkout {
    @Guide(description: "Completed exercise or cardio entries in the order mentioned.")
    var activities: [Activity]

    @Generable
    nonisolated struct Activity {
        @Guide(description: "A short name for the exercise or activity.")
        var name: String

        @Guide(description: "Explicitly stated set count. Omit when only a rep count is given. Do not default to one.")
        var sets: Int?

        @Guide(description: "Exact quote stating the number of sets for this activity, such as 'three sets' or '3 x 8'. Omit if sets are not stated.")
        var setEvidence: String?

        @Guide(description: "Repetitions per set, only if an exact count is given.")
        var reps: Int?

        @Guide(description: "The stated weight for this group, without converting it.")
        var weight: Double?

        @Guide(description: "The stated weight unit: kg or lb. Omit if unstated or unsupported.")
        var weightUnit: String?

        @Guide(description: "The stated elapsed time number, even if a distance is also given. Do not convert it. For 30 seconds use 30.")
        var elapsedTime: Double?

        @Guide(description: "The time unit explicitly stated for the elapsed time.")
        var elapsedUnit: ElapsedUnit?

        @Guide(description: "The stated distance, without converting it.")
        var distance: Double?

        @Guide(description: "The stated distance unit: m, km, or mi. Omit if unstated or unsupported.")
        var distanceUnit: String?

        @Guide(description: "Brief stated details that the other fields do not capture, such as a rep range or per-side load. Omit if none.")
        var notes: String?

        func exercise(from transcript: String) -> WorkoutExercise {
            WorkoutExercise(
                name: name,
                sets: verifiedSets(in: transcript),
                reps: reps.flatMap { $0 > 0 ? $0 : nil },
                weight: positive(weight),
                weightUnit: weightUnit.flatMap {
                    WorkoutExercise.WeightUnit(rawValue: $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased())
                },
                durationMinutes: positive(elapsedTime.flatMap { elapsedUnit?.minutes($0) }),
                distance: positive(distance),
                distanceUnit: distanceUnit.flatMap {
                    WorkoutExercise.DistanceUnit(rawValue: $0.trimmingCharacters(in: .whitespacesAndNewlines).lowercased())
                },
                notes: notes ?? ""
            ).cleanedUp
        }

        private func verifiedSets(in transcript: String) -> Int? {
            guard let sets, sets > 0,
                  let evidence = setEvidence?.trimmingCharacters(in: .whitespacesAndNewlines),
                  evidence.lowercased().contains(/\bsets?\b|\d+\s*[x×]\s*\d+/),
                  transcript.range(of: evidence, options: .caseInsensitive) != nil else { return nil }
            return sets
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
