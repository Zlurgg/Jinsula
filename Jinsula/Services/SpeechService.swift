//
//  SpeechService.swift
//  Jinsula
//
//  Speaks the guidance aloud using the system speech synthesiser
//  (AVSpeechSynthesizer, available since iOS 7 — safe on old devices).
//

import Foundation
import AVFoundation

final class SpeechService {
    private let synthesizer = AVSpeechSynthesizer()

    func speak(_ text: String) {
        // TODO: tune voice/rate for clarity. Skeleton only.
        let utterance = AVSpeechUtterance(string: text)
        synthesizer.speak(utterance)
    }

    func stop() {
        synthesizer.stopSpeaking(at: .immediate)
    }
}
