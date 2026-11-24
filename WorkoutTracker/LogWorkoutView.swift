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
    @State private var recordingTask: Task<Void, Never>?
    @State private var showingSaveError = false

    private var summary: String {
        transcriber.transcript.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                ScrollView {
                    Text(transcriber.transcript.isEmpty ? recordingPrompt : transcriber.transcript)
                        .font(.title3)
                        .foregroundStyle(transcriber.transcript.isEmpty ? .secondary : .primary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding()
                }

                if let error = transcriber.errorMessage {
                    Text(error).font(.footnote).foregroundStyle(.red)
                        .multilineTextAlignment(.center).padding(.horizontal)
                }

                Spacer()

                Button(action: toggleRecording) {
                    Image(systemName: transcriber.isRecording ? "stop.fill" : "mic.fill")
                        .font(.system(size: 30))
                        .frame(width: 84, height: 84)
                        .foregroundStyle(.white)
                        .background(transcriber.isRecording ? Color.red : Color.accentColor, in: Circle())
                }
                .disabled(recordingTask != nil)
                .accessibilityLabel(transcriber.isRecording ? "Stop recording" : "Start recording")
                .padding(.bottom, 40)
            }
            .navigationTitle("Log a Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        stopRecording()
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save", action: saveWorkout)
                        .disabled(summary.isEmpty)
                }
            }
            .alert("Couldn’t save workout", isPresented: $showingSaveError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Your transcript is still here. You can try saving again.")
            }
            .onDisappear(perform: stopRecording)
        }
    }

    private var recordingPrompt: String {
        if transcriber.isRecording { return "Listening…" }
        if recordingTask != nil { return "Preparing microphone…" }
        return "Tap the mic and describe your workout…"
    }

    private func toggleRecording() {
        if transcriber.isRecording {
            stopRecording()
        } else {
            recordingTask = Task {
                await transcriber.start()
                recordingTask = nil
            }
        }
    }

    private func stopRecording() {
        recordingTask?.cancel()
        transcriber.stop()
    }

    private func saveWorkout() {
        let workoutSummary = summary
        guard !workoutSummary.isEmpty else { return }

        stopRecording()
        let workout = Workout(summary: workoutSummary)
        context.insert(workout)
        do {
            try context.save()
            dismiss()
        } catch {
            context.delete(workout)
            showingSaveError = true
        }
    }
}
