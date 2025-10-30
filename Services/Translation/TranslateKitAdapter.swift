import Foundation

/// Adaptador simulado de traducción offline.
/// Luego puedes reemplazarlo con tu modelo local real.
final class TranslateKitAdapter: TranslationService {
    func translate(_ text: String, from source: String, to target: String) async throws -> String {
        // 👇 Esto solo simula una traducción
        return "[\(target.uppercased())] " + text
    }
}
