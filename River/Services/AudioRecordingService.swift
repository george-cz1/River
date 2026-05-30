import AVFoundation
import Foundation

@Observable
@MainActor
final class AudioRecordingService {
    enum RecordingState {
        case idle
        case recording
        case finished(URL)
        case failed(Error)
    }

    private(set) var state: RecordingState = .idle
    private(set) var elapsedSeconds: TimeInterval = 0
    private(set) var levels: [Float] = Array(repeating: -60, count: 40)

    private var recorder: AVAudioRecorder?
    private var levelTimer: Timer?
    private let maxDuration: TimeInterval = 120

    // MARK: - Permission

    func requestPermission() async -> Bool {
        #if os(iOS)
        return await AVAudioApplication.requestRecordPermission()
        #elseif os(macOS)
        let status = AVCaptureDevice.authorizationStatus(for: .audio)
        switch status {
        case .authorized: return true
        case .notDetermined: return await AVCaptureDevice.requestAccess(for: .audio)
        default: return false
        }
        #else
        return false
        #endif
    }

    // MARK: - Recording

    func startRecording() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
            .appendingPathExtension("m4a")

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        #if os(iOS)
        try AVAudioSession.sharedInstance().setCategory(.playAndRecord, mode: .default, options: .defaultToSpeaker)
        try AVAudioSession.sharedInstance().setActive(true)
        #endif

        let newRecorder = try AVAudioRecorder(url: url, settings: settings)
        newRecorder.isMeteringEnabled = true
        newRecorder.record(forDuration: maxDuration)

        recorder = newRecorder
        elapsedSeconds = 0
        levels = Array(repeating: -60, count: 40)
        state = .recording

        levelTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            Task { @MainActor [weak self] in self?.tick() }
        }
    }

    func stopRecording() {
        guard let recorder, recorder.isRecording else { return }
        let url = recorder.url
        recorder.stop()
        finalizeRecording(at: url)
    }

    func cancel() {
        recorder?.stop()
        recorder?.deleteRecording()
        cleanUp()
        state = .idle
    }

    // MARK: - Internals

    private func tick() {
        guard case .recording = state else { return }
        elapsedSeconds += 0.1

        recorder?.updateMeters()
        let level = recorder?.averagePower(forChannel: 0) ?? -60
        levels = Array(levels.dropFirst()) + [level]

        if elapsedSeconds >= maxDuration {
            stopRecording()
        }
    }

    private func finalizeRecording(at url: URL) {
        cleanUp()
        #if os(iOS)
        try? AVAudioSession.sharedInstance().setActive(false)
        #endif
        state = .finished(url)
    }

    private func cleanUp() {
        levelTimer?.invalidate()
        levelTimer = nil
        recorder = nil
    }
}
