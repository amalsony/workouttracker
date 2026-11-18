//
//  ContentView.swift
//  WorkoutTracker
//
//  Created by Amal Sony on 6/16/26.
//

import SwiftUI
import SwiftData

struct WorkoutsView: View {
    @Environment(\.modelContext) private var context
    @Query(sort: \Workout.date, order: .reverse) private var workouts: [Workout]
    @State private var showingLogSheet = false

    var body: some View {
        NavigationStack {
            List {
                ForEach(workouts) { workout in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(workout.summary)
                            .font(.headline)
                        Text(workout.date, style: .date)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .onDelete(perform: deleteWorkouts)
            }
            .navigationTitle("Workouts")
            .overlay {
                if workouts.isEmpty {
                    ContentUnavailableView(
                        "No Workouts Yet",
                        systemImage: "figure.run",
                        description: Text("Tap + to log your first workout.")
                    )
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarLeading) { EditButton() }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingLogSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                    .accessibilityLabel("Log a workout")
                }
            }
        }
        .sheet(isPresented: $showingLogSheet) {
            LogWorkoutView()
                .presentationDetents([.medium, .large])
        }
    }

    private func deleteWorkouts(at offsets: IndexSet) {
        for index in offsets {
            context.delete(workouts[index])
        }
    }
}

#Preview {
    WorkoutsView()
        .modelContainer(for: Workout.self, inMemory: true)
}
