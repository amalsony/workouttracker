import SwiftUI

struct WorkoutDetailView: View {
    let workout: Workout

    var body: some View {
        List {
            if !workout.exercises.isEmpty {
                Section("Exercises") {
                    ForEach(workout.exercises) { exercise in
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
    }
}
