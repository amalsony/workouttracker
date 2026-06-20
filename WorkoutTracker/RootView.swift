//
//  RootView.swift
//  WorkoutTracker
//
//  Created by Amal Sony on 6/17/26.
//

import SwiftUI
import SwiftData

struct RootView: View {
    @State private var showingLogSheet = false

    var body: some View {
        ZStack(alignment: .bottomTrailing) {
            TabView {
                Tab("Home", systemImage: "house.fill") {
                    HomeView()
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

            Button {
                showingLogSheet = true
            } label: {
                Image(systemName: "plus")
                    .font(.title2.weight(.semibold))
                    .padding()
            }
            .glassEffect(.regular.interactive())
            .padding(.trailing, 16)
            .padding(.bottom, 70)
            .accessibilityLabel("Log a workout")
        }
        .sheet(isPresented: $showingLogSheet) {
            LogWorkoutView()
                .presentationDetents([.medium, .large])
        }
    }
}
