import AVFoundation
import SpriteKit

/// Sound effect types
enum SoundEffect: String {
    // Tower sounds
    case towerPlace = "tower_place"
    case towerUpgrade = "tower_upgrade"
    case towerSell = "tower_sell"
    case machineGunFire = "mg_fire"
    case cannonFire = "cannon_fire"
    case laserFire = "laser_fire"
    case shotgunFire = "shotgun_fire"
    case splashFire = "splash_fire"
    case antiAirFire = "antiair_fire"
    case slowActivate = "slow_activate"
    case buffActivate = "buff_activate"
    
    // Enemy sounds
    case enemyDeath = "enemy_death"
    case enemyReachExit = "enemy_exit"
    case enemySpawn = "enemy_spawn"
    
    // Game sounds
    case waveStart = "wave_start"
    case waveComplete = "wave_complete"
    case levelComplete = "level_complete"
    case gameOver = "game_over"
    case victory = "victory"
    case buttonClick = "button_click"
    case invalidPlacement = "invalid_placement"
    case coinEarn = "coin_earn"
    case lifeLost = "life_lost"
}

/// Manages all game audio using procedural synthesis
final class AudioManager {
    
    static let shared = AudioManager()
    
    // Audio engine
    private var audioEngine: AVAudioEngine?
    private var playerNodes: [AVAudioPlayerNode] = []
    private var mixerNode: AVAudioMixerNode?
    private var audioFormat: AVAudioFormat?
    
    // Settings
    private(set) var soundEnabled: Bool = true
    private(set) var musicEnabled: Bool = true
    private var soundVolume: Float = 0.7
    private var musicVolume: Float = 0.4
    
    // Background music
    private var musicPlayer: AVAudioPlayer?
    
    // Cooldowns to prevent sound spam
    private var lastPlayedTimes: [SoundEffect: TimeInterval] = [:]
    private let minimumInterval: TimeInterval = 0.05
    
    private init() {
        setupAudioEngine()
        setupAudioSession()
    }
    
    private func setupAudioSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.ambient, mode: .default, options: [.mixWithOthers])
            try session.setActive(true)
        } catch {
            print("Audio session setup failed: \(error)")
        }
    }
    
    private func setupAudioEngine() {
        // Create a known-good format: stereo, 44.1kHz, float
        audioFormat = AVAudioFormat(standardFormatWithSampleRate: 44100, channels: 2)
        
        guard let format = audioFormat else {
            print("Failed to create audio format")
            return
        }
        
        audioEngine = AVAudioEngine()
        guard let engine = audioEngine else { return }
        
        mixerNode = engine.mainMixerNode
        guard let mixer = mixerNode else { return }
        
        // Create pool of player nodes with our known format
        for _ in 0..<8 {
            let player = AVAudioPlayerNode()
            engine.attach(player)
            engine.connect(player, to: mixer, format: format)
            playerNodes.append(player)
        }
        
        do {
            try engine.start()
        } catch {
            print("Audio engine start failed: \(error)")
            // Disable audio on failure
            audioEngine = nil
        }
    }
    
    // MARK: - Public Methods
    
    func playSound(_ effect: SoundEffect) {
        // Audio temporarily disabled due to format issues
        // TODO: Fix audio engine format compatibility
        return
        
        /*
        guard soundEnabled else { return }
        
        // Cooldown check
        let now = CACurrentMediaTime()
        if let lastPlayed = lastPlayedTimes[effect], now - lastPlayed < minimumInterval {
            return
        }
        lastPlayedTimes[effect] = now
        
        // Generate and play procedural sound
        generateAndPlaySound(for: effect)
        */
    }
    
    func toggleSound() {
        soundEnabled = !soundEnabled
    }
    
    func toggleMusic() {
        musicEnabled = !musicEnabled
        if musicEnabled {
            startBackgroundMusic()
        } else {
            stopBackgroundMusic()
        }
    }
    
    func startBackgroundMusic() {
        guard musicEnabled else { return }
        // Background music would be loaded from file here
        // For now, we'll skip actual music since we can't bundle audio files
    }
    
    func stopBackgroundMusic() {
        musicPlayer?.stop()
    }
    
    // MARK: - Procedural Sound Generation
    
    private func generateAndPlaySound(for effect: SoundEffect) {
        guard let engine = audioEngine, engine.isRunning else { return }
        
        let sampleRate: Double = 44100
        var frequency: Double = 440
        var duration: Double = 0.1
        var waveform: WaveformType = .sine
        var envelope: EnvelopeType = .percussive
        var volume: Float = soundVolume
        
        // Configure sound parameters based on effect type
        switch effect {
        case .machineGunFire:
            frequency = 800
            duration = 0.03
            waveform = .noise
            volume = soundVolume * 0.4
            
        case .cannonFire:
            frequency = 100
            duration = 0.2
            waveform = .noise
            envelope = .explosion
            volume = soundVolume * 0.6
            
        case .laserFire:
            frequency = 1200
            duration = 0.15
            waveform = .sawtooth
            envelope = .laser
            volume = soundVolume * 0.5
            
        case .shotgunFire:
            frequency = 200
            duration = 0.1
            waveform = .noise
            envelope = .percussive
            volume = soundVolume * 0.5
            
        case .splashFire:
            frequency = 150
            duration = 0.25
            waveform = .noise
            envelope = .explosion
            volume = soundVolume * 0.5
            
        case .antiAirFire:
            frequency = 2000
            duration = 0.08
            waveform = .square
            envelope = .percussive
            volume = soundVolume * 0.4
            
        case .slowActivate:
            frequency = 400
            duration = 0.3
            waveform = .sine
            envelope = .swell
            volume = soundVolume * 0.3
            
        case .buffActivate:
            frequency = 600
            duration = 0.2
            waveform = .sine
            envelope = .swell
            volume = soundVolume * 0.3
            
        case .towerPlace:
            frequency = 300
            duration = 0.15
            waveform = .triangle
            envelope = .percussive
            volume = soundVolume * 0.5
            
        case .towerUpgrade:
            frequency = 500
            duration = 0.3
            waveform = .sine
            envelope = .ascending
            volume = soundVolume * 0.5
            
        case .towerSell:
            frequency = 250
            duration = 0.2
            waveform = .sine
            envelope = .descending
            volume = soundVolume * 0.5
            
        case .enemyDeath:
            frequency = 150
            duration = 0.15
            waveform = .noise
            envelope = .percussive
            volume = soundVolume * 0.3
            
        case .enemyReachExit:
            frequency = 200
            duration = 0.3
            waveform = .sawtooth
            envelope = .descending
            volume = soundVolume * 0.4
            
        case .enemySpawn:
            frequency = 100
            duration = 0.1
            waveform = .sine
            envelope = .percussive
            volume = soundVolume * 0.2
            
        case .waveStart:
            frequency = 440
            duration = 0.5
            waveform = .sine
            envelope = .fanfare
            volume = soundVolume * 0.5
            
        case .waveComplete:
            frequency = 660
            duration = 0.4
            waveform = .sine
            envelope = .fanfare
            volume = soundVolume * 0.5
            
        case .levelComplete:
            frequency = 880
            duration = 0.8
            waveform = .sine
            envelope = .victory
            volume = soundVolume * 0.6
            
        case .gameOver:
            frequency = 150
            duration = 1.0
            waveform = .sawtooth
            envelope = .defeat
            volume = soundVolume * 0.6
            
        case .victory:
            frequency = 880
            duration = 1.2
            waveform = .sine
            envelope = .victory
            volume = soundVolume * 0.7
            
        case .buttonClick:
            frequency = 1000
            duration = 0.05
            waveform = .sine
            envelope = .percussive
            volume = soundVolume * 0.3
            
        case .invalidPlacement:
            frequency = 200
            duration = 0.2
            waveform = .square
            envelope = .percussive
            volume = soundVolume * 0.4
            
        case .coinEarn:
            frequency = 1500
            duration = 0.1
            waveform = .sine
            envelope = .percussive
            volume = soundVolume * 0.3
            
        case .lifeLost:
            frequency = 250
            duration = 0.3
            waveform = .sawtooth
            envelope = .descending
            volume = soundVolume * 0.5
        }
        
        // Generate audio buffer
        let buffer = generateAudioBuffer(
            frequency: frequency,
            duration: duration,
            sampleRate: sampleRate,
            waveform: waveform,
            envelope: envelope,
            volume: volume
        )
        
        // Play on available node
        playBuffer(buffer)
    }
    
    private func generateAudioBuffer(
        frequency: Double,
        duration: Double,
        sampleRate: Double,
        waveform: WaveformType,
        envelope: EnvelopeType,
        volume: Float
    ) -> AVAudioPCMBuffer? {
        
        guard let format = audioFormat else { return nil }
        
        // Always use 44100 to match our format
        let actualSampleRate: Double = 44100
        let frameCount = AVAudioFrameCount(duration * actualSampleRate)
        
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount) else {
            return nil
        }
        
        buffer.frameLength = frameCount
        
        guard let channelData = buffer.floatChannelData else {
            return nil
        }
        
        let channelCount = Int(format.channelCount)
        
        for frame in 0..<Int(frameCount) {
            let time = Double(frame) / actualSampleRate
            let normalizedTime = time / duration
            
            // Generate waveform
            var sample: Float = 0
            let phase = 2.0 * Double.pi * frequency * time
            
            switch waveform {
            case .sine:
                sample = Float(sin(phase))
            case .square:
                sample = sin(phase) > 0 ? 1.0 : -1.0
            case .triangle:
                sample = Float(2.0 * abs(2.0 * (time * frequency - floor(time * frequency + 0.5))) - 1.0)
            case .sawtooth:
                sample = Float(2.0 * (time * frequency - floor(time * frequency + 0.5)))
            case .noise:
                sample = Float.random(in: -1...1)
            }
            
            // Apply envelope
            let envelopeValue = getEnvelopeValue(normalizedTime: normalizedTime, type: envelope)
            let finalSample = sample * envelopeValue * volume
            
            // Write to all channels (mono or stereo)
            for channel in 0..<channelCount {
                channelData[channel][frame] = finalSample
            }
        }
        
        return buffer
    }
    
    private func getEnvelopeValue(normalizedTime: Double, type: EnvelopeType) -> Float {
        let t = normalizedTime
        
        switch type {
        case .percussive:
            return Float(exp(-5.0 * t))
        case .explosion:
            return Float(exp(-3.0 * t) * (1 - exp(-50.0 * t)))
        case .laser:
            return Float((1 - t) * (0.5 + 0.5 * sin(30.0 * t)))
        case .swell:
            return Float(sin(Double.pi * t))
        case .ascending:
            return Float(t * exp(-2.0 * t) * 4)
        case .descending:
            return Float((1 - t) * (1 - t))
        case .fanfare:
            let attack = min(t * 10, 1.0)
            let decay = exp(-2.0 * max(0, t - 0.1))
            return Float(attack * decay)
        case .victory:
            let segments = [0.0, 0.2, 0.4, 0.6, 0.8, 1.0]
            _ = [1.0, 1.25, 1.5, 1.25, 1.5, 2.0]  // freqMults - reserved for future use
            var idx = 0
            for i in 0..<segments.count-1 {
                if t >= segments[i] && t < segments[i+1] { idx = i; break }
            }
            let localT = (t - segments[idx]) / (segments[idx+1] - segments[idx])
            return Float(sin(Double.pi * localT) * 0.8)
        case .defeat:
            return Float((1 - t) * (1 - t) * (0.5 + 0.5 * sin(5.0 * t)))
        }
    }
    
    private func playBuffer(_ buffer: AVAudioPCMBuffer?) {
        guard let buffer = buffer,
              let engine = audioEngine,
              engine.isRunning,
              let format = audioFormat else { return }
        
        // Verify format matches to prevent crash
        guard buffer.format.channelCount == format.channelCount,
              buffer.format.sampleRate == format.sampleRate else {
            print("Audio format mismatch - skipping playback")
            return
        }
        
        // Find available player node
        for player in playerNodes {
            if !player.isPlaying {
                player.scheduleBuffer(buffer, at: nil, options: [])
                player.play()
                return
            }
        }
        
        // If all players busy, use first one
        if let player = playerNodes.first {
            player.stop()
            player.scheduleBuffer(buffer, at: nil, options: [])
            player.play()
        }
    }
}

// MARK: - Supporting Types

enum WaveformType {
    case sine
    case square
    case triangle
    case sawtooth
    case noise
}

enum EnvelopeType {
    case percussive
    case explosion
    case laser
    case swell
    case ascending
    case descending
    case fanfare
    case victory
    case defeat
}
