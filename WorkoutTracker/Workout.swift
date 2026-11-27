//
//  Workout.swift
//  WorkoutTracker
//
//  Created by Amal Sony on 6/16/26.
//

import Foundation
import SwiftData

@Model
final class Workout {
    var date: Date
    var summary: String
    private var exerciseData: Data?
    
    init(date: Date = .now, summary: String) {
        self.date = date
        self.summary = summary
    }

    convenience init(summary: String, exercises: [WorkoutExercise]) throws {
        self.init(summary: summary)
        exerciseData = try Self.encodeExercises(exercises)
    }

    var exercises: [WorkoutExercise] {
        guard let exerciseData else { return [] }
        return (try? JSONDecoder().decode([WorkoutExercise].self, from: exerciseData)) ?? []
    }

    func saveEdits(date: Date, summary: String, exercises: [WorkoutExercise], in context: ModelContext) throws {
        let updatedExerciseData = try Self.encodeExercises(exercises)
        let previousDate = self.date
        let previousSummary = self.summary
        let previousExerciseData = exerciseData

        self.date = date
        self.summary = summary
        exerciseData = updatedExerciseData

        do {
            try context.save()
        } catch {
            self.date = previousDate
            self.summary = previousSummary
            exerciseData = previousExerciseData
            throw error
        }
    }

    private static func encodeExercises(_ exercises: [WorkoutExercise]) throws -> Data? {
        guard !exercises.isEmpty else { return nil }
        return try JSONEncoder().encode(exercises)
    }
}
