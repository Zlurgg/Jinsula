//
//  SpeechService.swift
//  Jinsula
//
//  Speaks the guidance aloud using the system speech synthesiser
//  (AVSpeechSynthesizer, available since iOS 7 — safe on old devices).
//
//  Safety: the audio session is configured `.playback` so guidance is heard
//  even when the ring/silent switch is on — a low-glucose warning must never
//  be muted. See SPEC.md "Daily-use screen §3".
//

import Foundation
import AVFoundation

final class SpeechService {
    private let synthesizer = AVSpeechSynthesizer()

    /// Speaks the card's headline, then its detail, as one calm sequence.
    func speak(headline: String, detail: String) {
        activatePlaybackSession()
        stop()
        enqueue(headline)
        enqueue(detail)
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
    }

    // MARK: - Helpers

    private func enqueue(_ text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        let utterance = AVSpeechUtterance(string: trimmed)
        // Slightly slower than default for clarity for an elderly listener.
        utterance.rate = AVSpeechUtteranceDefaultSpeechRate * 0.9
        utterance.voice = AVSpeechSynthesisVoice(language: "en-GB")
        synthesizer.speak(utterance)
    }

    /// `.playback` overrides the silent switch; `.duckOthers` lowers other audio
    /// briefly rather than stopping it. Failures are non-fatal — speech still
    /// plays through the default session.
    private func activatePlaybackSession() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playback, options: [.duckOthers])
        try? session.setActive(true)
    }
}
