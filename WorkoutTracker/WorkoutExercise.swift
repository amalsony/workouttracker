import Foundation

nonisolated struct WorkoutExercise: Codable, Identifiable {
    enum WeightUnit: String, CaseIterable, Codable {
        case kilograms = "kg"
        case pounds = "lb"
    }

    enum DistanceUnit: String, CaseIterable, Codable {
        case meters = "m"
        case kilometers = "km"
        case miles = "mi"
    }

    var id = UUID()
    var name = ""
    var sets: Int?
    var reps: Int?
    var weight: Double?
    var weightUnit: WeightUnit?
    var durationMinutes: Double?
    var distance: Double?
    var distanceUnit: DistanceUnit?
    var notes = ""

    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && (sets ?? 1) > 0
            && (reps ?? 1) > 0
            && [weight, durationMinutes, distance].compactMap { $0 }.allSatisfy { $0.isFinite && $0 > 0 }
    }

    var cleanedUp: Self {
        var exercise = self
        exercise.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        exercise.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        if weight == nil { exercise.weightUnit = nil }
        if distance == nil { exercise.distanceUnit = nil }
        return exercise
    }

    var metrics: String {
        var parts: [String] = []
        if let sets {
            parts.append(sets == 1 ? "1 set" : "\(sets.formatted()) sets")
        }
        if let reps {
            parts.append(reps == 1 ? "1 rep" : "\(reps.formatted()) reps")
        }
        if let weight {
            parts.append("\(weight.formatted()) \(weightUnit?.rawValue ?? "weight (unit unspecified)")")
        }
        if let durationMinutes {
            parts.append("\(durationMinutes.formatted()) min")
        }
        if let distance {
            parts.append("\(distance.formatted()) \(distanceUnit?.rawValue ?? "distance (unit unspecified)")")
        }
        return parts.joined(separator: " · ")
    }
}
