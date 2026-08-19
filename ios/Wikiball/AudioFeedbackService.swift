import AVFoundation
import Foundation

enum BackgroundMusicTrack: String {
    case intro = "IntroScreen"
    case mainGame = "MainGame"
}

enum CrowdAmbienceTrack: String {
    case continuous = "CrowdAmbienceContinuous"
    case realistic = "CrowdAmbienceRealistic"
    case stadium = "CrowdAmbienceStadium"
}

private enum CrowdReactionTrack: String {
    case goalMassive = "CrowdGoalMassive"
    case goalRoar = "CrowdGoalRoar"
    case loud = "CrowdLoudReaction"
    case short = "CrowdShortReaction"
}

@MainActor
final class AudioFeedbackService {
    private let engine = AVAudioEngine()
    private let player = AVAudioPlayerNode()
    private let sampleRate = 44_100.0
    private var musicPlayer: AVAudioPlayer?
    private var currentMusicTrack: BackgroundMusicTrack?
    private var ambiencePlayer: AVAudioPlayer?
    private var currentAmbienceTrack: CrowdAmbienceTrack?
    private var reactionPlayer: AVAudioPlayer?
    private var reactionToken = UUID()

    init() {
        engine.attach(player)
        if let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1) {
            engine.connect(player, to: engine.mainMixerNode, format: format)
        }
        engine.mainMixerNode.outputVolume = 0.42
        engine.prepare()
    }

    func play(_ cue: MatchFeedbackKind) {
        activateAudioSession()
        if !engine.isRunning { try? engine.start() }
        guard let buffer = makeBuffer(for: cue) else { return }
        player.stop()
        player.scheduleBuffer(buffer, at: nil, options: .interrupts)
        player.play()
        playCrowdReaction(for: cue)
    }

    func playMusic(_ track: BackgroundMusicTrack) {
        if currentMusicTrack == track, musicPlayer?.isPlaying == true { return }
        guard let url = Bundle.main.url(forResource: track.rawValue, withExtension: "mp3")
            ?? Bundle.main.url(forResource: track.rawValue, withExtension: "mp3", subdirectory: "Audio") else { return }
        activateAudioSession()
        do {
            let newPlayer = try AVAudioPlayer(contentsOf: url)
            newPlayer.numberOfLoops = -1
            newPlayer.volume = 0.18
            newPlayer.prepareToPlay()
            newPlayer.play()
            musicPlayer?.stop()
            musicPlayer = newPlayer
            currentMusicTrack = track
        } catch {
            musicPlayer = nil
            currentMusicTrack = nil
        }
    }

    func stopMusic() {
        musicPlayer?.stop()
        musicPlayer = nil
        currentMusicTrack = nil
    }

    func playCrowdAmbience(_ track: CrowdAmbienceTrack) {
        if currentAmbienceTrack == track, ambiencePlayer?.isPlaying == true { return }
        guard let url = bundledAudioURL(named: track.rawValue),
              let newPlayer = try? AVAudioPlayer(contentsOf: url) else { return }
        activateAudioSession()
        newPlayer.numberOfLoops = -1
        newPlayer.volume = 0.055
        newPlayer.prepareToPlay()
        newPlayer.play()
        ambiencePlayer?.stop()
        ambiencePlayer = newPlayer
        currentAmbienceTrack = track
    }

    func stopCrowdAmbience() {
        ambiencePlayer?.stop()
        ambiencePlayer = nil
        currentAmbienceTrack = nil
        reactionPlayer?.stop()
        reactionPlayer = nil
    }

    private func playCrowdReaction(for cue: MatchFeedbackKind) {
        let track: CrowdReactionTrack
        let volume: Float
        let duration: Duration
        switch cue {
        case .goal:
            track = Bool.random() ? .goalMassive : .goalRoar
            volume = 0.30
            duration = .seconds(4.2)
        case .nearMiss:
            track = .short
            volume = 0.22
            duration = .seconds(1.8)
        case .farMiss:
            track = .loud
            volume = 0.18
            duration = .seconds(2.0)
        case .hint:
            return
        }
        guard let url = bundledAudioURL(named: track.rawValue),
              let newPlayer = try? AVAudioPlayer(contentsOf: url) else { return }
        newPlayer.volume = volume
        newPlayer.prepareToPlay()
        newPlayer.play()
        reactionPlayer?.stop()
        reactionPlayer = newPlayer
        let token = UUID()
        reactionToken = token
        Task { [weak self] in
            try? await Task.sleep(for: duration)
            guard self?.reactionToken == token else { return }
            self?.reactionPlayer?.setVolume(0, fadeDuration: 0.35)
            try? await Task.sleep(for: .milliseconds(350))
            guard self?.reactionToken == token else { return }
            self?.reactionPlayer?.stop()
            self?.reactionPlayer = nil
        }
    }

    private func bundledAudioURL(named name: String) -> URL? {
        Bundle.main.url(forResource: name, withExtension: "mp3")
            ?? Bundle.main.url(forResource: name, withExtension: "mp3", subdirectory: "Audio")
    }

    private func activateAudioSession() {
        #if os(iOS)
        try? AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])
        try? AVAudioSession.sharedInstance().setActive(true)
        #endif
    }

    private func makeBuffer(for cue: MatchFeedbackKind) -> AVAudioPCMBuffer? {
        let duration: Double = switch cue {
        case .goal: 0.85
        case .nearMiss: 0.42
        case .farMiss: 0.48
        case .hint: 0.24
        }
        guard let format = AVAudioFormat(standardFormatWithSampleRate: sampleRate, channels: 1),
              let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: AVAudioFrameCount(sampleRate * duration)),
              let samples = buffer.floatChannelData?[0] else { return nil }
        buffer.frameLength = buffer.frameCapacity

        for frame in 0..<Int(buffer.frameLength) {
            let time = Double(frame) / sampleRate
            let progress = time / duration
            let attack = min(1, progress * 24)
            let release = pow(max(0, 1 - progress), cue == .goal ? 1.2 : 2.1)
            let envelope = attack * release
            let signal = sample(for: cue, time: time, progress: progress)
            samples[frame] = Float(signal * envelope)
        }
        return buffer
    }

    private func sample(for cue: MatchFeedbackKind, time: Double, progress: Double) -> Double {
        let phase = 2 * Double.pi * time
        switch cue {
        case .goal:
            let root = sin(phase * 523.25) * 0.38
            let third = sin(phase * 659.25) * 0.28
            let fifth = sin(phase * 783.99) * 0.22
            let whistle = sin(phase * (880 + progress * 220)) * 0.12
            return root + third + fifth + whistle
        case .nearMiss:
            return sin(phase * (520 - progress * 130)) * 0.62 + sin(phase * 1_040) * 0.12
        case .farMiss:
            return sin(phase * (155 - progress * 55)) * 0.65 + sin(phase * 91) * 0.20
        case .hint:
            return sin(phase * (680 + progress * 420)) * 0.55 + sin(phase * 1_360) * 0.12
        }
    }
}
