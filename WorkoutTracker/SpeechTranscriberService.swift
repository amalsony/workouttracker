//
//  SpeechTranscriberService.swift
//  WorkoutTracker
//
//  Created by Amal Sony on 6/19/26.
//

import Foundation
import AVFoundation
import Speech

@MainActor
@Observable
final class SpeechTranscriberService {
    var transcript: String = ""
    var isRecording = false
    var errorMessage: String?

    private let audioEngine = AVAudioEngine()
    private var transcriber: SpeechTranscriber?
    private var analyzer: SpeechAnalyzer?
    private var inputBuilder: AsyncStream<AnalyzerInput>.Continuation?
    private var recognizerTask: Task<Void, Never>?
    private var analyzerFormat: AVAudioFormat?
    private var finalized = ""

    func start() async {
        guard !isRecording else { return }
        transcript = ""; finalized = ""; errorMessage = nil

        guard await micPermissionGranted() else {
            errorMessage = "Microphone access is needed to log workouts by voice."
            return
        }

        do {
            let locale = Locale.current
            let transcriber = SpeechTranscriber(
                locale: locale,
                transcriptionOptions: [],
                reportingOptions: [.volatileResults],
                attributeOptions: []
            )
            self.transcriber = transcriber

            try await ensureModel(for: transcriber, locale: locale)

            let analyzer = SpeechAnalyzer(modules: [transcriber])
            self.analyzer = analyzer
            self.analyzerFormat = await SpeechAnalyzer.bestAvailableAudioFormat(compatibleWith: [transcriber])

            let (stream, builder) = AsyncStream<AnalyzerInput>.makeStream()
            self.inputBuilder = builder

            recognizerTask = Task {
                do {
                    for try await result in transcriber.results {
                        let text = String(result.text.characters)
                        if result.isFinal {
                            finalized += text
                            transcript = finalized
                        } else {
                            transcript = finalized + text   // live guess
                        }
                    }
                } catch {
                    errorMessage = error.localizedDescription
                }
            }

            try await analyzer.start(inputSequence: stream)
            try startAudio()
            isRecording = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func stop() {
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        inputBuilder?.finish()
        recognizerTask?.cancel()
        isRecording = false
    }

    private func micPermissionGranted() async -> Bool {
        await withCheckedContinuation { cont in
            AVAudioApplication.requestRecordPermission { granted in
                cont.resume(returning: granted)
            }
        }
    }

    private func ensureModel(for transcriber: SpeechTranscriber, locale: Locale) async throws {
        let supported = await SpeechTranscriber.supportedLocales
        guard supported.contains(where: { $0.identifier(.bcp47) == locale.identifier(.bcp47) }) else {
            throw NSError(domain: "Transcriber", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: "This language isn't supported for transcription."])
        }
        let installed = await SpeechTranscriber.installedLocales
        if installed.contains(where: { $0.identifier(.bcp47) == locale.identifier(.bcp47) }) { return }
        if let request = try await AssetInventory.assetInstallationRequest(supporting: [transcriber]) {
            try await request.downloadAndInstall()
        }
    }

    private func startAudio() throws {
        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.record, mode: .measurement, options: .duckOthers)
        try session.setActive(true, options: .notifyOthersOnDeactivation)

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        guard let analyzerFormat else { return }
        let converter = AVAudioConverter(from: recordingFormat, to: analyzerFormat)
        let builder = inputBuilder

        inputNode.installTap(onBus: 0, bufferSize: 4096, format: recordingFormat) { buffer, _ in
            guard let converter,
                  let converted = AVAudioPCMBuffer(
                    pcmFormat: analyzerFormat,
                    frameCapacity: AVAudioFrameCount(analyzerFormat.sampleRate * 0.4)) else { return }
            var nsError: NSError?
            converter.convert(to: converted, error: &nsError) { _, status in
                status.pointee = .haveData
                return buffer
            }
            if nsError == nil { builder?.yield(AnalyzerInput(buffer: converted)) }
        }

        audioEngine.prepare()
        try audioEngine.start()
    }
}
