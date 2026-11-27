import SwiftUI

struct WorkoutDetailView: View {
    let workout: Workout
    @State private var showingEditor = false

    var body: some View {
        let exercises = workout.exercises

        List {
            if !exercises.isEmpty {
                Section("Exercises") {
                    ForEach(exercises) { exercise in
                        VStack(alignment: .leading, spacing: 4) {
                            Text(exercise.name).font(.headline)
                            if !exercise.metrics.isEmpty {
                                Text(exercise.metrics)
                                    .font(.subheadline)
                                    .foregroundStyle(.secondary)
                            }
                            ForEach(exercise.setEntries) { set in
                                LabeledContent(exercise.setLabel(for: set.id)) {
                                    Text(set.metrics)
                                        .foregroundStyle(.secondary)
                                }
                                .font(.subheadline)
                            }
                            if !exercise.notes.isEmpty {
                                Text(exercise.notes)
                                    .font(.subheadline)
                            }
                        }
                        .accessibilityElement(children: .combine)
                    }
                }
            }
            if !workout.summary.isEmpty {
                Section("Workout notes") {
                    Text(workout.summary)
                        .textSelection(.enabled)
                }
            }
        }
        .navigationTitle(workout.date.formatted(date: .abbreviated, time: .omitted))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button("Edit") { showingEditor = true }
            }
        }
        .sheet(isPresented: $showingEditor) {
            EditWorkoutView(workout: workout)
        }
    }
}
