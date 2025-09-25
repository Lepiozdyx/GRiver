import UIKit
import Combine
import AVFoundation

@MainActor
final class SettingsManager: ObservableObject {
    
    static let shared = SettingsManager()
    
    @Published var isSoundEnabled: Bool {
        didSet {
            defaults.set(isSoundEnabled, forKey: "soundOn")
        }
    }
    
    @Published var isMusicEnabled: Bool {
        didSet {
            defaults.set(isMusicEnabled, forKey: "musicOn")
            
            if isMusicEnabled {
                playBackgroundMusic()
            } else {
                stopBackgroundMusic()
            }
        }
    }
    
    private let defaults = UserDefaults.standard
    private var audioPlayer: AVAudioPlayer?
    private var clickPlayer: AVAudioPlayer?
    
    private init() {
        self.isMusicEnabled = defaults.bool(forKey: "musicOn")
        self.isSoundEnabled = defaults.bool(forKey: "soundOn")
        
        setupDefaultSettings()
        setupAudioSession()
        prepareBackgroundMusic()
        prepareClickSound()
    }
    
    // MARK: - Methods
    
    // MARK: Sound
    func toggleSound() {
        isSoundEnabled.toggle()
    }
    
    func playClick() {
        guard isSoundEnabled,
              let player = clickPlayer,
              !player.isPlaying else { return }
        
        player.play()
    }
    
    // MARK: Music
    func toggleMusic() {
        isMusicEnabled.toggle()
    }
    
    func playBackgroundMusic() {
        guard isMusicEnabled,
              let player = audioPlayer,
              !player.isPlaying else { return }
        
        audioPlayer?.play()
    }
    
    func stopBackgroundMusic() {
        audioPlayer?.pause()
    }
    
    
    // MARK: - Private methods
    private func setupDefaultSettings() {
        if defaults.object(forKey: "soundOn") == nil {
            defaults.set(true, forKey: "soundOn")
            isSoundEnabled = true
        }
        
        if defaults.object(forKey: "musicOn") == nil {
            defaults.set(true, forKey: "musicOn")
            isMusicEnabled = true
        }
    }
    
    private func setupAudioSession() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.ambient, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print(error)
        }
    }
    
    private func prepareBackgroundMusic() {
        guard let url = Bundle.main.url(forResource: "music", withExtension: "wav") else {
            return
        }
        
        do {
            audioPlayer = try AVAudioPlayer(contentsOf: url)
            audioPlayer?.numberOfLoops = -1
            audioPlayer?.prepareToPlay()
        } catch {
            print(error)
        }
    }
    
    private func prepareClickSound() {
        guard let url = Bundle.main.url(forResource: "click", withExtension: "mp3") else {
            return
        }
        
        do {
            clickPlayer = try AVAudioPlayer(contentsOf: url)
            clickPlayer?.numberOfLoops = 0
            clickPlayer?.prepareToPlay()
        } catch {
            print(error)
        }
    }
}
