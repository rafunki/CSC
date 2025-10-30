import SwiftUI

struct ContentView: View {
    // MARK: - Estado UI
    @State private var partial = ""
    @State private var finals: [String] = []
    @State private var detectedLang: String?
    @State private var translatedText: String?
    @State private var isRecording = false
    @State private var mockMode = true
    @State private var mockInput = ""

    // MARK: - Servicios
    private let speech = SpeechRecognizerService()
    private let nlp = LanguageDetectionService()
    private let translator: TranslationService = TranslateKitAdapter() // 👈 cambia si tienes otro traductor
    @State private var targetLang: String = "en"

    var body: some View {
        VStack(spacing: 16) {
            Text("Demo: Voz → Texto → Idioma → Traducción")
                .font(.title2).bold()

            RoundedRectangle(cornerRadius: 12)
                .fill(.gray.opacity(0.12))
                .frame(height: 80)
                .overlay(
                    Text(partial.isEmpty ? "Habla o escribe para comenzar…" : partial)
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                )

            if let lang = detectedLang {
                Text("Idioma detectado: \(lang)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            if let translated = translatedText {
                Text("Traducción: \(translated)")
                    .font(.callout)
                    .foregroundStyle(.secondary)
                    .padding(.top, 4)
            }

            List(finals, id: \.self) { Text($0) }

            // MARK: - Mock mode (sin micrófono)
            Toggle("Mock mode (sin micrófono)", isOn: $mockMode)

            if mockMode {
                TextField("Escribe una frase para simular ASR…", text: $mockInput)
                    .textFieldStyle(.roundedBorder)
                Button("Procesar mock") {
                    let txt = mockInput.trimmingCharacters(in: .whitespacesAndNewlines)
                    guard txt.isEmpty == false else { return }

                    partial = ""
                    finals.append(txt)

                    if let src = nlp.detectLanguage(for: txt) {
                        detectedLang = src
                        Task {
                            let translated = try? await translator.translate(txt, from: src, to: targetLang)
                            await MainActor.run { translatedText = translated }
                        }
                    }
                    mockInput = ""
                }
                .buttonStyle(.bordered)
            }

            // MARK: - Botón principal
            Button(isRecording ? "Detener" : "Iniciar") {
                if mockMode { return }
                if isRecording {
                    speech.stop()
                    isRecording = false
                } else {
                    startRecognition()
                }
            }
            .buttonStyle(.borderedProminent)
        }
        .padding()
        .onDisappear { speech.stop() }
    }

    // MARK: - Lógica ASR
    private func startRecognition() {
        Task {
            do {
                try await SpeechRecognizerService.ensurePermissions()

                speech.onPartial = { txt in
                    partial = txt
                }

                speech.onFinal = { txt in
                    partial = ""
                    finals.append(txt)

                    if let src = nlp.detectLanguage(for: txt) {
                        detectedLang = src
                        Task {
                            do {
                                let translated = try await translator.translate(txt, from: src, to: targetLang)
                                await MainActor.run { translatedText = translated }
                            } catch {
                                print("Error traduciendo:", error.localizedDescription)
                            }
                        }
                    }
                }

                speech.onError = { err in
                    print("ASR error:", err.localizedDescription)
                }

                try speech.start(locale: Locale(identifier: "es-MX"))
                isRecording = true
            } catch {
                print("Error al iniciar reconocimiento:", error.localizedDescription)
            }
        }
    }
}
