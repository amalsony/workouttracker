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
    
    init(date: Date = .now, summary: String) {
        self.date = date
        self.summary = summary
    }
}
