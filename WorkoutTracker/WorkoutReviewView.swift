import SwiftUI

struct WorkoutReviewView: View {
    let notes: String
    @Binding var exercises: [WorkoutExercise]

    var body: some View {
        Form {
            Section {
                Text("Check the exercises before saving. Each set can have its own reps and weight.")
                    .foregroundStyle(.secondary)
            }
            ForEach($exercises) { $exercise in
                Section {
                    TextField("Exercise name", text: $exercise.name)
                    ForEach($exercise.setEntries) { $set in
                        WorkoutSetEditor(label: exercise.setLabel(for: set.id), set: $set) {
                            let id = set.id
                            exercise.setEntries.removeAll { $0.id == id }
                        }
                        if (set.count ?? 1) > 1 {
                            Button("Separate One Set") {
                                let id = set.id
                                guard let index = exercise.setEntries.firstIndex(where: { $0.id == id }),
                                      let count = exercise.setEntries[index].count, count > 1 else { return }
                                var singleSet = exercise.setEntries[index]
                                singleSet.id = UUID()
                                singleSet.count = 1
                                exercise.setEntries[index].count = count - 1
                                exercise.setEntries.insert(singleSet, at: index + 1)
                            }
                        }
                    }
                    Button("Add Set", systemImage: "plus") {
                        let unit = exercise.setEntries.last?.weightUnit
                        exercise.setEntries.append(WorkoutSet(weightUnit: unit))
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
                        Text("Enter an exercise name and use valid numbers. Weight can be zero.")
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
            if !notes.isEmpty {
                Section("Workout notes") {
                    Text(notes)
                        .textSelection(.enabled)
                }
            }
        }
        .scrollDismissesKeyboard(.interactively)
    }
}

private struct WorkoutSetEditor: View {
    let label: String
    @Binding var set: WorkoutSet
    let onRemove: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(label).font(.subheadline.weight(.semibold))
                Spacer()
                Button(role: .destructive, action: onRemove) {
                    Image(systemName: "trash")
                }
                .buttonStyle(.borderless)
                .accessibilityLabel("Remove \(label)")
            }
            LabeledContent("Reps") {
                TextField("Reps", value: $set.reps, format: .number, prompt: Text("Optional"))
                    .keyboardType(.numberPad)
                    .accessibilityLabel("\(label) reps")
            }
            LabeledContent("Weight") {
                TextField("Weight", value: $set.weight, format: .number, prompt: Text("Optional"))
                    .keyboardType(.decimalPad)
                    .accessibilityLabel("\(label) weight")
            }
            if set.weight != nil {
                Picker("Weight unit", selection: $set.weightUnit) {
                    Text("Unspecified").tag(nil as WorkoutExercise.WeightUnit?)
                    ForEach(WorkoutExercise.WeightUnit.allCases, id: \.self) { unit in
                        Text(unit.rawValue).tag(Optional(unit))
                    }
                }
                .pickerStyle(.menu)
                .accessibilityLabel("\(label) weight unit")
            }
        }
        .padding(.vertical, 4)
    }
}
