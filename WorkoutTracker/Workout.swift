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
        if !exercises.isEmpty {
            exerciseData = try JSONEncoder().encode(exercises)
        }
    }

    var exercises: [WorkoutExercise] {
        guard let exerciseData else { return [] }
        return (try? JSONDecoder().decode([WorkoutExercise].self, from: exerciseData)) ?? []
    }
}
