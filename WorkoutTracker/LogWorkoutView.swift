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
    @State private var showingSaveError = false

    private var summary: String {
        transcriber.transcript.trimmingCharacters(in: .whitespacesAndNewlines)
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                ScrollView {
                    Text(transcriber.transcript.isEmpty
                         ? "Tap the mic and describe your workout…"
                         : transcriber.transcript)
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

                Button {
                    Task {
                        transcriber.isRecording ? transcriber.stop() : await transcriber.start()
                    }
                } label: {
                    Image(systemName: transcriber.isRecording ? "stop.fill" : "mic.fill")
                        .font(.system(size: 30))
                        .frame(width: 84, height: 84)
                        .foregroundStyle(.white)
                        .background(transcriber.isRecording ? Color.red : Color.accentColor, in: Circle())
                }
                .padding(.bottom, 40)
            }
            .navigationTitle("Log a Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { transcriber.stop(); dismiss() }
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
            .onDisappear { transcriber.stop() }
            .task { await transcriber.start() }
        }
    }

    private func saveWorkout() {
        let workoutSummary = summary
        guard !workoutSummary.isEmpty else { return }

        transcriber.stop()
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
