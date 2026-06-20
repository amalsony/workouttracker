//
//  LogWorkoutView.swift
//  WorkoutTracker
//
//  Created by Amal Sony on 6/19/26.
//

import SwiftUI

struct LogWorkoutView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var transcriber = SpeechTranscriberService()

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
                    Button("Done") {
                        transcriber.stop()
                        // next step: save / parse transcriber.transcript
                        dismiss()
                    }
                    .disabled(transcriber.transcript.isEmpty)
                }
            }
            .onDisappear { transcriber.stop() }
        }
    }
}
