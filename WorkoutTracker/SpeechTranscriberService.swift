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
    private var analyzer: SpeechAnalyzer?
    private var inputBuilder: AsyncStream<AnalyzerInput>.Continuation?
    private var recognizerTask: Task<Void, Never>?
    private var analyzerFormat: AVAudioFormat?
    private var finalized = ""
    private var hasAudioSession = false
    private var hasInputTap = false

    func start() async {
        guard !isRecording, !Task.isCancelled else { return }
        let priorNotes = transcript.trimmingCharacters(in: .whitespacesAndNewlines)
        finalized = ""
        errorMessage = nil

        let hasPermission = await micPermissionGranted()
        guard !Task.isCancelled else { return }
        guard hasPermission else {
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
            try await ensureModel(for: transcriber, locale: locale)
            guard !Task.isCancelled else { return }

            let analyzer = SpeechAnalyzer(modules: [transcriber])
            self.analyzer = analyzer
            self.analyzerFormat = await SpeechAnalyzer.bestAvailableAudioFormat(compatibleWith: [transcriber])
            guard !Task.isCancelled else { return }

            let (stream, builder) = AsyncStream<AnalyzerInput>.makeStream()
            self.inputBuilder = builder

            recognizerTask = Task {
                do {
                    for try await result in transcriber.results {
                        guard !Task.isCancelled else { return }
                        let text = String(result.text.characters)
                        if result.isFinal {
                            finalized += text
                        }
                        let recordingText = result.isFinal ? finalized : finalized + text
                        transcript = [priorNotes, recordingText].filter { !$0.isEmpty }.joined(separator: "\n")
                    }
                } catch {
                    if !Task.isCancelled {
                        errorMessage = error.localizedDescription
                    }
                }
            }

            try await analyzer.start(inputSequence: stream)
            guard !Task.isCancelled else { return }
            try startAudio()
            isRecording = true
        } catch {
            if !Task.isCancelled {
                stop()
                errorMessage = error.localizedDescription
            }
        }
    }

    func finishRecording() async {
        guard isRecording, let analyzer else { return }
        endAudioInput()

        do {
            try await analyzer.finalizeAndFinishThroughEndOfInput()
            await recognizerTask?.value
            try Task.checkCancellation()
            recognizerTask = nil
            self.analyzer = nil
        } catch {
            if !Task.isCancelled {
                stop()
                errorMessage = "Couldn’t finish transcribing. You can review and edit the captured text."
            }
        }
    }

    func stop() {
        endAudioInput()
        recognizerTask?.cancel()
        recognizerTask = nil
        if let analyzer {
            self.analyzer = nil
            Task { await analyzer.cancelAndFinishNow() }
        }
    }

    private func endAudioInput() {
        if hasInputTap {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
            hasInputTap = false
        }
        inputBuilder?.finish()
        inputBuilder = nil
        if hasAudioSession {
            try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
            hasAudioSession = false
        }
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
        hasAudioSession = true

        let inputNode = audioEngine.inputNode
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        guard recordingFormat.sampleRate > 0, recordingFormat.channelCount > 0,
              let analyzerFormat,
              let converter = AVAudioConverter(from: recordingFormat, to: analyzerFormat) else {
            throw CocoaError(.featureUnsupported)
        }

        let builder = inputBuilder

        inputNode.installTap(onBus: 0, bufferSize: 4096, format: recordingFormat) { buffer, _ in
            // Size the output buffer to the actual sample-rate ratio, not a guess.
            let ratio = analyzerFormat.sampleRate / recordingFormat.sampleRate
            let capacity = AVAudioFrameCount(Double(buffer.frameLength) * ratio) + 1
            guard let converted = AVAudioPCMBuffer(pcmFormat: analyzerFormat,
                                                   frameCapacity: capacity) else { return }

            // Hand the converter the buffer
            var provided = false
            var nsError: NSError?
            converter.convert(to: converted, error: &nsError) { _, outStatus in
                if provided {
                    outStatus.pointee = .noDataNow
                    return nil
                }
                provided = true
                outStatus.pointee = .haveData
                return buffer
            }

            if nsError == nil, converted.frameLength > 0 {
                builder?.yield(AnalyzerInput(buffer: converted))
            }
        }
        hasInputTap = true

        audioEngine.prepare()
        try audioEngine.start()
    }
}
