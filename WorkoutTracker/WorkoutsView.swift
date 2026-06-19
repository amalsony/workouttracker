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
                    Button(action: addSample) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
    }

    private func addSample() {
        context.insert(Workout(summary: "Push day — bench, shoulders, triceps"))
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
