//
//  LogWorkoutView.swift
//  WorkoutTracker
//
//  Created by Amal Sony on 6/19/26.
//

import SwiftUI
import SwiftData

struct LogWorkoutView: View {
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var context
    @State private var transcriber = SpeechTranscriberService()
    @State private var speechTask: Task<Void, Never>?
    @State private var speechProgress = "Preparing microphone…"
    @State private var parseTask: Task<Void, Never>?
    @State private var parseError: String?
    @State private var exercises: [WorkoutExercise] = []
    @State private var reviewedNotes: String?
    @State private var showingReview = false
    @State private var showingSaveError = false

    private var notes: String {
        transcriber.transcript.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    private var canReview: Bool {
        !notes.isEmpty && speechTask == nil && !transcriber.isRecording && parseTask == nil
    }

    var body: some View {
        NavigationStack {
            Group {
                if showingReview {
                    WorkoutReviewView(notes: notes, exercises: $exercises)
                } else {
                    captureForm
                }
            }
            .navigationTitle(showingReview ? "Review Workout" : "Log a Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if showingReview {
                        Button("Back") { showingReview = false }
                    } else {
                        Button("Cancel") {
                            cancelTasks()
                            dismiss()
                        }
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    if showingReview {
                        Button("Save") { saveWorkout(exercises: exercises) }
                            .disabled(exercises.isEmpty || !exercises.allSatisfy(\.isValid))
                    } else {
                        Button("Review", action: parseWorkout)
                            .disabled(!canReview)
                    }
                }
            }
            .alert("Couldn’t save workout", isPresented: $showingSaveError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Your changes are still here. You can try saving again.")
            }
        }
        .onDisappear(perform: cancelTasks)
    }

    private var captureForm: some View {
        @Bindable var transcriber = transcriber

        return Form {
            Section {
                TextField(
                    "e.g. Squats, 3 sets of 8 at 60 kg, then a 20-minute run",
                    text: $transcriber.transcript,
                    axis: .vertical
                )
                .accessibilityLabel("Workout notes")
                .lineLimit(3...7)
                .disabled(transcriber.isRecording || speechTask != nil || parseTask != nil)
            } header: {
                Text("Workout notes")
            } footer: {
                Text("Type or record what you did, then tap Review to check the extracted exercises.")
            }

            Section {
                Button(action: toggleRecording) {
                    if transcriber.isRecording {
                        Label("Stop recording", systemImage: "stop.circle.fill")
                            .foregroundStyle(.red)
                    } else {
                        Label(notes.isEmpty ? "Record workout" : "Add voice notes", systemImage: "mic")
                    }
                }
                .disabled(speechTask != nil || parseTask != nil)

                if speechTask != nil {
                    ProgressView(speechProgress)
                } else if transcriber.isRecording {
                    Label("Listening…", systemImage: "waveform")
                        .foregroundStyle(.secondary)
                }

                if let error = transcriber.errorMessage {
                    Text(error)
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            if parseTask != nil {
                Section {
                    ProgressView("Extracting exercises…")
                }
            }
            if let parseError {
                Section {
                    Text(parseError)
                        .foregroundStyle(.secondary)
                }
            }
            if !notes.isEmpty {
                Section {
                    Button("Save as Note") { saveWorkout(exercises: []) }
                        .disabled(!canReview)
                }
            }
        }
    }

    private func toggleRecording() {
        guard speechTask == nil, parseTask == nil else { return }
        let isFinishing = transcriber.isRecording
        speechProgress = isFinishing ? "Finishing transcript…" : "Preparing microphone…"
        parseError = nil
        speechTask = Task {
            defer { speechTask = nil }
            if isFinishing {
                await transcriber.finishRecording()
            } else {
                await transcriber.start()
            }
        }
    }

    private func parseWorkout() {
        guard canReview else { return }
        let source = notes
        parseError = nil
        if source == reviewedNotes {
            showingReview = true
            return
        }
        parseTask = Task {
            defer { parseTask = nil }
            do {
                let result = try await WorkoutParser().parse(source)
                try Task.checkCancellation()
                exercises = result
                reviewedNotes = source
                showingReview = true
            } catch let error as WorkoutParser.ParseError {
                if !Task.isCancelled { parseError = error.localizedDescription }
            } catch {
                if !Task.isCancelled {
                    parseError = "Couldn’t extract workout details. Try shorter notes or save them as a note."
                }
            }
        }
    }

    private func cancelTasks() {
        parseTask?.cancel()
        speechTask?.cancel()
        transcriber.stop()
    }

    private func saveWorkout(exercises: [WorkoutExercise]) {
        guard canReview, exercises.allSatisfy(\.isValid) else { return }

        do {
            let workout = try Workout(summary: notes, exercises: exercises.map(\.cleanedUp))
            context.insert(workout)
            do {
                try context.save()
            } catch {
                context.delete(workout)
                throw error
            }
            dismiss()
        } catch {
            showingSaveError = true
        }
    }
}
