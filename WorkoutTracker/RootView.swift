//
//  RootView.swift
//  WorkoutTracker
//
//  Created by Amal Sony on 6/17/26.
//

import SwiftUI
import SwiftData

struct RootView: View {
    var body: some View {
        TabView {
            Tab("Home", systemImage: "house.fill") {
                WorkoutsView()
            }
            
            Tab("Workouts", systemImage: "figure.strengthtraining.traditional") {
                WorkoutsView()
            }
            
            Tab("Progress", systemImage: "chart.line.uptrend.xyaxis") {
                StatsView()
            }
            
            Tab("Profile", systemImage: "person.fill") {
                ProfileView()
            }
        }
        .tabBarMinimizeBehavior(.onScrollDown)
    }
}

#Preview {
    RootView()
        .modelContainer(for: Workout.self)
}
