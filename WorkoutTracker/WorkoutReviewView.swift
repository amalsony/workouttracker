import SwiftUI

struct WorkoutReviewView: View {
    let notes: String
    @Binding var exercises: [WorkoutExercise]

    var body: some View {
        Form {
            Section {
                Text("Check the exercises before saving. Only the exercise name is required.")
                    .foregroundStyle(.secondary)
            }
            ForEach($exercises) { $exercise in
                Section {
                    TextField("Exercise name", text: $exercise.name)
                    LabeledContent("Sets") {
                        TextField("Sets", value: $exercise.sets, format: .number, prompt: Text("Optional"))
                            .keyboardType(.numberPad)
                    }
                    LabeledContent("Reps per set") {
                        TextField("Reps per set", value: $exercise.reps, format: .number, prompt: Text("Optional"))
                            .keyboardType(.numberPad)
                    }
                    LabeledContent("Weight") {
                        TextField("Weight", value: $exercise.weight, format: .number, prompt: Text("Optional"))
                            .keyboardType(.decimalPad)
                    }
                    if exercise.weight != nil {
                        Picker("Weight unit", selection: $exercise.weightUnit) {
                            Text("Unspecified").tag(nil as WorkoutExercise.WeightUnit?)
                            ForEach(WorkoutExercise.WeightUnit.allCases, id: \.self) { unit in
                                Text(unit.rawValue).tag(Optional(unit))
                            }
                        }
                    }
                    LabeledContent("Duration (min)") {
                        TextField("Duration in minutes", value: $exercise.durationMinutes, format: .number, prompt: Text("Optional"))
                            .keyboardType(.decimalPad)
                    }
                    LabeledContent("Distance") {
                        TextField("Distance", value: $exercise.distance, format: .number, prompt: Text("Optional"))
                            .keyboardType(.decimalPad)
                    }
                    if exercise.distance != nil {
                        Picker("Distance unit", selection: $exercise.distanceUnit) {
                            Text("Unspecified").tag(nil as WorkoutExercise.DistanceUnit?)
                            ForEach(WorkoutExercise.DistanceUnit.allCases, id: \.self) { unit in
                                Text(unit.rawValue).tag(Optional(unit))
                            }
                        }
                    }
                    TextField("Notes", text: $exercise.notes, axis: .vertical)
                        .lineLimit(1...4)

                    if !exercise.isValid {
                        Text("Enter an exercise name and use positive numbers for measurements.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }

                    Button("Remove exercise", role: .destructive) {
                        let id = exercise.id
                        exercises.removeAll { $0.id == id }
                    }
                }
            }
            Section {
                Button("Add exercise", systemImage: "plus") {
                    exercises.append(WorkoutExercise())
                }
            }
            Section("Workout notes") {
                Text(notes)
                    .textSelection(.enabled)
            }
        }
        .scrollDismissesKeyboard(.interactively)
    }
}
