//
//  WorkoutTrackerApp.swift
//  WorkoutTracker
//
//  Created by Amal Sony on 6/16/26.
//

import SwiftUI
import SwiftData

@main
struct WorkoutTrackerApp: App {
    var body: some Scene {
        WindowGroup {
            RootView()
        }
        .modelContainer(for: Workout.self)
    }
}
