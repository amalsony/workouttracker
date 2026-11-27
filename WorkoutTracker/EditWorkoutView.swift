import SwiftUI
import SwiftData

struct EditWorkoutView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context

    let workout: Workout

    @State private var date: Date
    @State private var notes: String
    @State private var exercises: [WorkoutExercise]
    @State private var showingSaveError = false

    init(workout: Workout) {
        self.workout = workout
        _date = State(initialValue: workout.date)
        _notes = State(initialValue: workout.summary)
        _exercises = State(initialValue: workout.exercises)
    }

    private var trimmedNotes: String {
        notes.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canSave: Bool {
        (!trimmedNotes.isEmpty || !exercises.isEmpty) && exercises.allSatisfy(\.isValid)
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    DatePicker("Date", selection: $date, displayedComponents: .date)
                }
                WorkoutExerciseFields(exercises: $exercises)
                Section("Workout notes") {
                    TextField("Notes", text: $notes, axis: .vertical)
                        .lineLimit(3...7)
                }
            }
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Edit Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: save)
                        .disabled(!canSave)
                }
            }
            .alert("Couldn’t save changes", isPresented: $showingSaveError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Your edits are still here. You can try saving again.")
            }
        }
    }

    private func save() {
        guard canSave else { return }

        do {
            try workout.saveEdits(
                date: date,
                summary: trimmedNotes,
                exercises: exercises.map(\.cleanedUp),
                in: context
            )
            dismiss()
        } catch {
            showingSaveError = true
        }
    }
}
