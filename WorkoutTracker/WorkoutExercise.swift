import Foundation

nonisolated struct WorkoutSet: Codable, Identifiable {
    var id = UUID()
    var reps: Int?
    var weight: Double?
    var weightUnit: WorkoutExercise.WeightUnit?
    // Nil means the workout mentions reps or weight without a set count.
    var count: Int? = 1

    var isValid: Bool {
        (count ?? 1) > 0
            && (reps ?? 1) > 0
            && weight.map { $0.isFinite && $0 >= 0 } != false
    }

    var cleanedUp: Self {
        var set = self
        if weight == nil { set.weightUnit = nil }
        return set
    }

    var metrics: String {
        var parts: [String] = []
        if let reps {
            parts.append(reps == 1 ? "1 rep" : "\(reps.formatted()) reps")
        }
        if let weight {
            parts.append("\(weight.formatted()) \(weightUnit?.rawValue ?? "weight (unit unspecified)")")
        }
        return parts.joined(separator: " · ")
    }
}

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
    var setEntries: [WorkoutSet] = []
    var durationMinutes: Double?
    var distance: Double?
    var distanceUnit: DistanceUnit?
    var notes = ""

    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            && setEntries.allSatisfy(\.isValid)
            && [durationMinutes, distance].compactMap { $0 }.allSatisfy { $0.isFinite && $0 > 0 }
    }

    var cleanedUp: Self {
        var exercise = self
        exercise.name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        exercise.notes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
        exercise.setEntries = setEntries.map(\.cleanedUp)
        if distance == nil { exercise.distanceUnit = nil }
        return exercise
    }

    func setLabel(for id: WorkoutSet.ID) -> String {
        guard let index = setEntries.firstIndex(where: { $0.id == id }) else { return "Set" }
        switch setEntries[index].count {
        case nil: return "Set count unspecified"
        case 1:
            if setEntries[..<index].contains(where: { ($0.count ?? 0) > 1 }) { return "Set" }
            let number = setEntries[..<index].filter { $0.count == 1 }.count + 1
            return "Set \(number)"
        case let count?: return "\(count.formatted()) matching sets"
        }
    }

    var metrics: String {
        var parts: [String] = []
        if let durationMinutes {
            parts.append("\(durationMinutes.formatted()) min")
        }
        if let distance {
            parts.append("\(distance.formatted()) \(distanceUnit?.rawValue ?? "distance (unit unspecified)")")
        }
        return parts.joined(separator: " · ")
    }
}

nonisolated extension WorkoutExercise {
    private enum CodingKeys: String, CodingKey {
        case id, name, setEntries, durationMinutes, distance, distanceUnit, notes
    }

    private enum LegacyStrengthKeys: String, CodingKey {
        case sets, reps, weight, weightUnit
    }

    init(from decoder: Decoder) throws {
        let data = try decoder.container(keyedBy: CodingKeys.self)
        id = try data.decode(UUID.self, forKey: .id)
        name = try data.decode(String.self, forKey: .name)
        durationMinutes = try data.decodeIfPresent(Double.self, forKey: .durationMinutes)
        distance = try data.decodeIfPresent(Double.self, forKey: .distance)
        distanceUnit = try data.decodeIfPresent(DistanceUnit.self, forKey: .distanceUnit)
        notes = try data.decode(String.self, forKey: .notes)

        if let savedSets = try data.decodeIfPresent([WorkoutSet].self, forKey: .setEntries) {
            setEntries = savedSets
        } else {
            let legacy = try decoder.container(keyedBy: LegacyStrengthKeys.self)
            let count = try legacy.decodeIfPresent(Int.self, forKey: .sets)
            let reps = try legacy.decodeIfPresent(Int.self, forKey: .reps)
            let weight = try legacy.decodeIfPresent(Double.self, forKey: .weight)
            let unit = try legacy.decodeIfPresent(WeightUnit.self, forKey: .weightUnit)
            if count != nil || reps != nil || weight != nil {
                // Older workouts recorded one group of matching sets per exercise.
                setEntries = [WorkoutSet(id: id, reps: reps, weight: weight, weightUnit: unit, count: count)]
            }
        }
    }
}
