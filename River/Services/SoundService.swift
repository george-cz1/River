import Foundation
import AVFoundation
import UIKit

/// Service for playing sounds and haptic feedback
@MainActor
class SoundService: FeedbackServiceProtocol {
    static let shared = SoundService()

    private var audioPlayer: AVAudioPlayer?
    private let hapticGenerator = UIImpactFeedbackGenerator(style: .medium)

    private let soundStorageKey = UserDefaultsKeys.transitionSound
    private let hapticStorageKey = UserDefaultsKeys.hapticsEnabled

    var selectedSound: TransitionSound {
        get {
            if let soundRaw = UserDefaults.standard.string(forKey: soundStorageKey),
               let sound = TransitionSound(rawValue: soundRaw) {
                return sound
            }
            return .chime
        }
        set {
            UserDefaults.standard.set(newValue.rawValue, forKey: soundStorageKey)
        }
    }

    var hapticsEnabled: Bool {
        get {
            // Default to true if not set
            if UserDefaults.standard.object(forKey: hapticStorageKey) == nil {
                return true
            }
            return UserDefaults.standard.bool(forKey: hapticStorageKey)
        }
        set {
            UserDefaults.standard.set(newValue, forKey: hapticStorageKey)
        }
    }

    private init() {
        hapticGenerator.prepare()
        configureAudioSession()
    }

    // MARK: - Audio Session Configuration

    private func configureAudioSession() {
        do {
            let audioSession = AVAudioSession.sharedInstance()
            try audioSession.setCategory(.ambient, mode: .default)
            try audioSession.setActive(true)
        } catch {
            print("Failed to configure audio session: \(error)")
        }
    }

    // MARK: - Play Sound

    func play(_ sound: TransitionSound) {
        guard sound != .none else { return }

        // Try to find the sound file
        guard let soundURL = Bundle.main.url(forResource: sound.rawValue, withExtension: "wav") else {
            // If sound file doesn't exist, play system sound as fallback
            playSystemSound()
            return
        }

        do {
            audioPlayer = try AVAudioPlayer(contentsOf: soundURL)
            audioPlayer?.prepareToPlay()
            audioPlayer?.play()
        } catch {
            print("Failed to play sound: \(error)")
            playSystemSound()
        }
    }

    /// Play current selected sound
    func playSelectedSound() {
        play(selectedSound)
    }

    /// Play system sound as fallback
    private func playSystemSound() {
        // Play a subtle system sound (notification sound)
        AudioServicesPlaySystemSound(1016) // SMS received tone 5
    }

    // MARK: - Haptic Feedback

    func playHaptic(_ style: UIImpactFeedbackGenerator.FeedbackStyle = .medium) {
        guard hapticsEnabled else { return }

        let generator = UIImpactFeedbackGenerator(style: style)
        generator.prepare()
        generator.impactOccurred()
    }

    /// Play haptic with current settings
    func playSelectedHaptic() {
        playHaptic()
    }

    // MARK: - Combined Sound & Haptic

    func playTransitionFeedback() {
        playSelectedSound()
        playSelectedHaptic()
    }

    // MARK: - FeedbackServiceProtocol

    func playTransitionSound(_ soundName: String?) {
        if let soundName = soundName, let sound = TransitionSound(rawValue: soundName) {
            play(sound)
        } else {
            playSelectedSound()
        }
    }

    func playHaptic(style: HapticStyle) {
        let uiStyle: UIImpactFeedbackGenerator.FeedbackStyle
        switch style {
        case .light:
            uiStyle = .light
        case .medium:
            uiStyle = .medium
        case .heavy:
            uiStyle = .heavy
        case .success:
            uiStyle = .medium
        case .warning:
            uiStyle = .medium
        case .error:
            uiStyle = .heavy
        }
        playHaptic(uiStyle)
    }
}
