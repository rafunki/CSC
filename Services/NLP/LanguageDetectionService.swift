import Foundation
import NaturalLanguage

struct LanguageDetectionService {
    func detectLanguage(for text: String) -> String? {
        guard text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty == false else { return nil }
        let recognizer = NLLanguageRecognizer()
        recognizer.processString(text)
        return recognizer.dominantLanguage?.rawValue
    }

    func isDetectable(_ text: String) -> Bool {
        text.trimmingCharacters(in: .whitespacesAndNewlines).count >= 8
    }
}
