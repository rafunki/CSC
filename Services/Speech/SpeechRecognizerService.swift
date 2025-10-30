import Foundation
import AVFoundation
import Speech

final class SpeechRecognizerService: NSObject {
    var onPartial: ((String) -> Void)?
    var onFinal: ((String) -> Void)?
    var onError: ((Error) -> Void)?

    private let audioEngine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var recognizer: SFSpeechRecognizer?
    private var task: SFSpeechRecognitionTask?

    // Permisos
    static func ensurePermissions() async throws {
        try await withCheckedThrowingContinuation { (cont: CheckedContinuation<Void, Error>) in
            SFSpeechRecognizer.requestAuthorization { status in
                guard status == .authorized else {
                    cont.resume(throwing: NSError(
                        domain: "ASR", code: 1,
                        userInfo: [NSLocalizedDescriptionKey: "Speech no autorizado (\(status))"]
                    ))
                    return
                }
                AVAudioSession.sharedInstance().requestRecordPermission { ok in
                    if ok {
                        cont.resume(returning: ())
                    } else {
                        cont.resume(throwing: NSError(
                            domain: "ASR", code: 2,
                            userInfo: [NSLocalizedDescriptionKey: "Micrófono no autorizado"]
                        ))
                    }
                }
            }
        }
    }

    // Iniciar reconocimiento
    func start(locale: Locale = Locale(identifier: "es-MX")) throws {
        stop()
        recognizer = SFSpeechRecognizer(locale: locale)
        guard recognizer?.isAvailable == true else {
            throw NSError(domain: "ASR", code: 3,
                          userInfo: [NSLocalizedDescriptionKey: "Recognizer no disponible"])
        }

        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.record, mode: .measurement, options: [.duckOthers])
        try session.setActive(true, options: .notifyOthersOnDeactivation)

        request = SFSpeechAudioBufferRecognitionRequest()
        request?.shouldReportPartialResults = true

        let input = audioEngine.inputNode
        let format = input.outputFormat(forBus: 0)
        input.removeTap(onBus: 0)
        input.installTap(onBus: 0, bufferSize: 2048, format: format) { [weak self] buffer, _ in
            self?.request?.append(buffer)
        }

        audioEngine.prepare()
        try audioEngine.start()

        task = recognizer?.recognitionTask(with: request!) { [weak self] result, error in
            if let error = error {
                self?.onError?(error)
                self?.stop()
                return
            }
            guard let res = result else { return }
            let text = res.bestTranscription.formattedString
            res.isFinal ? self?.onFinal?(text) : self?.onPartial?(text)
        }
    }

    // Detener
    func stop() {
        task?.cancel(); task = nil
        request?.endAudio(); request = nil
        if audioEngine.isRunning {
            audioEngine.stop()
            audioEngine.inputNode.removeTap(onBus: 0)
        }
        try? AVAudioSession.sharedInstance().setActive(false)
    }
}
