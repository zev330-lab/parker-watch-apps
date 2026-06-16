#if os(watchOS) || os(iOS)
import AVFoundation

public final class SpeechEngine: NSObject {
    public static let shared = SpeechEngine()
    private var synth = AVSpeechSynthesizer()

    public func speak(_ text: String) {
        stop()
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, mode: .spokenAudio, options: .duckOthers)
        try? session.setActive(true)
        let clean = text.unicodeScalars
            .filter { !$0.properties.isEmojiPresentation && !$0.properties.isEmoji || $0.value < 128 }
            .reduce("") { $0 + String($1) }
            .trimmingCharacters(in: .whitespaces)
        let utterance = AVSpeechUtterance(string: clean.isEmpty ? text : clean)
        utterance.rate = 0.42
        utterance.pitchMultiplier = 1.08
        utterance.volume = 1.0
        utterance.voice = AVSpeechSynthesisVoice(language: "en-US")
        synth.speak(utterance)
    }

    public func stop() {
        if synth.isSpeaking { synth.stopSpeaking(at: .immediate) }
    }

    public var isSpeaking: Bool { synth.isSpeaking }
}
#endif
