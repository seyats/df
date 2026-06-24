import Foundation
import AVFoundation
import PhotosUI
import SwiftUI
import Combine

/// Сервис для работы с медиа: фото, видео, аудио, файлы.
final class MediaService: NSObject, ObservableObject {
    static let shared = MediaService()

    @Published var isRecording = false
    @Published var recordingDuration: TimeInterval = 0

    private var audioRecorder: AVAudioRecorder?
    private var recordingURL: URL?
    private var recordingTimer: Timer?

    // MARK: - Запись голоса
    func startRecording() {
        let session = AVAudioSession.sharedInstance()
        try? session.setCategory(.playAndRecord, mode: .default)
        try? session.setActive(true)

        let tempDir = FileManager.default.temporaryDirectory
        recordingURL = tempDir.appendingPathComponent("voice_\(UUID().uuidString).m4a")

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 44100,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.high.rawValue
        ]

        audioRecorder = try? AVAudioRecorder(url: recordingURL!, settings: settings)
        audioRecorder?.record()
        isRecording = true
        recordingDuration = 0

        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { [weak self] _ in
            self?.recordingDuration += 0.1
        }
    }

    func stopRecording() -> URL? {
        audioRecorder?.stop()
        isRecording = false
        recordingTimer?.invalidate()
        recordingTimer = nil
        return recordingURL
    }

    func cancelRecording() {
        audioRecorder?.stop()
        isRecording = false
        recordingTimer?.invalidate()
        recordingTimer = nil
        if let url = recordingURL {
            try? FileManager.default.removeItem(at: url)
        }
    }

    // MARK: - Загрузка медиа
    func uploadMedia(_ data: Data, filename: String, mimeType: String) async throws -> String {
        let path = "storage/v1/object/media/\(UUID().uuidString)_\(filename)"
        let urlString = "\(Constants.supabaseURL)/\(path)"
        guard let url = URL(string: urlString) else { throw APIError.invalidURL }
        var req = URLRequest(url: url)
        req.httpMethod = "POST"
        req.setValue(Constants.supabaseAnonKey, forHTTPHeaderField: "apikey")
        if let token = KeychainService.shared.authToken {
            req.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        req.setValue(mimeType, forHTTPHeaderField: "Content-Type")
        req.httpBody = data
        let (_, response) = try await URLSession.shared.data(for: req)
        guard let http = response as? HTTPURLResponse, (200...299).contains(http.statusCode) else {
            throw APIError.invalidResponse
        }
        return "\(Constants.supabaseURL)/\(path)"
    }

    // MARK: - Фото (системный пикер)
    func requestPhotoLibraryPermission() async -> Bool {
        let status = await PHPhotoLibrary.requestAuthorization(for: .readWrite)
        return status == .authorized || status == .limited
    }
}
