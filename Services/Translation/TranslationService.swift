import Foundation

protocol TranslationService {
    func translate(_ text: String, from source: String, to target: String) async throws -> String
}

struct NoOpTranslationService: TranslationService {
    func translate(_ text: String, from source: String, to target: String) async throws -> String {
        return text // versión base sin traducción
    }
}
