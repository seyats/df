import Foundation
import CallKit
import AVFoundation
import Observation

/// Сервис звонков: CallKit + WebRTC сигнальный канал через SocketService.
@Observable final class CallService: NSObject {
    static let shared = CallService()

    var isInCall = false
    var isMuted = false
    var isSpeakerOn = false
    var callState: CallState = .idle
    var remoteUserID: String?
    var callDuration: TimeInterval = 0

    private let callController = CXCallController()
    private let provider: CXProvider
    private var callUUID: UUID?
    private var durationTimer: Timer?
    private var isOutgoing = false

    enum CallState {
        case idle
        case ringing
        case connecting
        case active
        case ended
    }

    override init() {
        let config = CXProviderConfiguration()
        config.supportsVideo = true
        config.includesCallsInRecents = true
        config.supportedHandleTypes = [.generic]
        config.maximumCallGroups = 1
        config.maximumCallsPerCallGroup = 1
        provider = CXProvider(configuration: config)
        super.init()
        provider.setDelegate(self, queue: nil)
    }

    // MARK: - Исходящий звонок
    func startCall(to userID: String, chatID: String, isVideo: Bool = false) {
        let handle = CXHandle(type: .generic, value: userID)
        callUUID = UUID()
        let startAction = CXStartCallAction(call: callUUID!, handle: handle)
        startAction.isVideo = isVideo
        let transaction = CXTransaction(action: startAction)
        callController.request(transaction) { [weak self] error in
            if error == nil {
                self?.isOutgoing = true
                self?.remoteUserID = userID
                self?.callState = .ringing
                self?.sendSignal(.offer, chatID: chatID)
            }
        }
    }

    // MARK: - Входящий звонок
    func reportIncomingCall(from userID: String, chatID: String, isVideo: Bool = false) {
        callUUID = UUID()
        let update = CXCallUpdate()
        update.remoteHandle = CXHandle(type: .generic, value: userID)
        update.hasVideo = isVideo
        provider.reportNewIncomingCall(with: callUUID!, update: update) { [weak self] _ in
            self?.remoteUserID = userID
        }
    }

    // MARK: - Управление звонком
    func endCall() {
        guard let uuid = callUUID else { return }
        let endAction = CXEndCallAction(call: uuid)
        callController.request(CXTransaction(action: endAction)) { _ in }
    }

    func toggleMute() {
        isMuted.toggle()
        let action = CXSetMutedCallAction(call: callUUID ?? UUID(), muted: isMuted)
        callController.request(CXTransaction(action: action)) { _ in }
    }

    func toggleSpeaker() {
        isSpeakerOn.toggle()
        let audioSession = AVAudioSession.sharedInstance()
        try? audioSession.overrideOutputAudioPort(isSpeakerOn ? .speaker : .none)
    }

    func answerCall() {
        guard let uuid = callUUID else { return }
        let answerAction = CXAnswerCallAction(call: uuid)
        callController.request(CXTransaction(action: answerAction)) { [weak self] _ in
            self?.callState = .connecting
        }
    }

    // MARK: - Сигналы
    private func sendSignal(_ type: SocketService.CallSignalType, chatID: String, sdp: String? = nil) {
        let signal = SocketService.CallSignal(
            type: type,
            fromUserID: KeychainService.shared.currentUserID ?? "",
            chatID: chatID,
            sdp: sdp,
            candidate: nil,
            sdpMid: nil,
            sdpMLineIndex: nil
        )
        SocketService.shared.sendCallSignal(signal)
    }

    // MARK: - Таймер длительности
    private func startDurationTimer() {
        durationTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { [weak self] _ in
            self?.callDuration += 1
        }
    }

    private func stopDurationTimer() {
        durationTimer?.invalidate()
        durationTimer = nil
        callDuration = 0
    }
}

// MARK: - CXProviderDelegate
extension CallService: CXProviderDelegate {
    func providerDidReset(_ provider: CXProvider) {
        callState = .idle
        isInCall = false
        stopDurationTimer()
    }

    func provider(_ provider: CXProvider, perform action: CXAnswerCallAction) {
        callState = .active
        isInCall = true
        startDurationTimer()
        action.fulfill()
    }

    func provider(_ provider: CXProvider, perform action: CXEndCallAction) {
        callState = .ended
        isInCall = false
        stopDurationTimer()
        remoteUserID = nil
        action.fulfill()

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.callState = .idle
        }
    }

    func provider(_ provider: CXProvider, perform action: CXSetMutedCallAction) {
        isMuted = action.isMuted
        action.fulfill()
    }
}
