import Foundation
import Network
import Combine

/// WebSocket-сервис для real-time сообщений, статусов и сигнального канала WebRTC.
/// Использует NWConnection (Network.framework) для постоянного соединения.
final class SocketService: ObservableObject {
    static let shared = SocketService()

    @Published var isConnected = false
    @Published var lastReceivedMessage: MessageModel?
    @Published var lastTypingEvent: (chatID: String, userID: String)?
    @Published var lastOnlineStatus: (userID: String, isOnline: Bool)?
    @Published var lastCallSignal: CallSignal?

    private var connection: NWConnection?
    private var reconnectAttempts = 0
    private var reconnectTask: Task<Void, Never>?
    private let queue = DispatchQueue(label: "app.lumina.socket")

    struct CallSignal {
        let type: CallSignalType
        let fromUserID: String
        let chatID: String
        let sdp: String?
        let candidate: String?
        let sdpMid: String?
        let sdpMLineIndex: Int32?
    }

    enum CallSignalType: String {
        case offer, answer, iceCandidate, hangup, ringing
    }

    func connect() {
        // В локальном режиме не подключаемся к WebSocket — сообщения
        // доставляются напрямую через LocalBackend.
        guard Constants.isSupabaseConfigured else {
            #if DEBUG
            print("[SocketService] Supabase не настроен — работаем в локальном режиме.")
            #endif
            return
        }
        guard let url = URL(string: Constants.supabaseURL.replacingOccurrences(of: "https", with: "wss") + "/realtime/v1/websocket"),
              let host = url.host else { return }
        let port: UInt16 = 443
        let endpoint = NWEndpoint.hostPort(host: NWEndpoint.Host(host), port: NWEndpoint.Port(integerLiteral: port))
        let params = NWParameters.tls
        params.defaultProtocolStack.applicationProtocols = []
        connection = NWConnection(to: endpoint, using: params)

        connection?.stateUpdateHandler = { [weak self] state in
            guard let self = self else { return }
            Task { @MainActor in
                switch state {
                case .ready:
                    self.isConnected = true
                    self.reconnectAttempts = 0
                    self.subscribe()
                case .failed, .cancelled:
                    self.isConnected = false
                    self.scheduleReconnect()
                default:
                    break
                }
            }
        }

        connection?.receiveMessage { [weak self] data, _, _, error in
            if let data = data {
                self?.handleMessage(data)
            }
            if error == nil {
                self?.connection?.receiveMessage { d, _, _, e in
                    if let d = d { self?.handleMessage(d) }
                    if e == nil { self?.connection?.receiveMessage { da, _, _, er in
                        if let da = da { self?.handleMessage(da) }
                    }}
                }
            }
        }

        connection?.start(queue: queue)
    }

    func disconnect() {
        reconnectTask?.cancel()
        connection?.cancel()
        connection = nil
        isConnected = false
    }

    // MARK: - Отправка сообщения
    func sendMessage(_ message: MessageModel) {
        if Constants.useLocalBackend {
            // Локальный режим: сохраняем через APIService и обновляем @Published.
            Task { @MainActor in
                do {
                    let saved = try await APIService.shared.sendMessage(message)
                    self.lastReceivedMessage = saved
                } catch {
                    #if DEBUG
                    print("[SocketService] local sendMessage error: \(error)")
                    #endif
                }
            }
            return
        }
        guard let data = try? JSONEncoder().encode(message) else { return }
        connection?.send(content: data, completion: .contentProcessed({ _ in }))
    }

    func sendTyping(chatID: String, userID: String) {
        let payload: [String: Any] = ["type": "typing", "chat_id": chatID, "user_id": userID]
        sendJSON(payload)
    }

    func markRead(chatID: String, userID: String) {
        let payload: [String: Any] = ["type": "mark_read", "chat_id": chatID, "user_id": userID]
        sendJSON(payload)
    }

    func sendOnlineStatus(userID: String, isOnline: Bool) {
        let payload: [String: Any] = ["type": "presence", "user_id": userID, "online": isOnline]
        sendJSON(payload)
    }

    // MARK: - WebRTC сигналы
    func sendCallSignal(_ signal: CallSignal) {
        let payload: [String: Any] = [
            "type": "call_signal",
            "signal_type": signal.type.rawValue,
            "from_user_id": signal.fromUserID,
            "chat_id": signal.chatID,
            "sdp": signal.sdp as Any,
            "candidate": signal.candidate as Any,
            "sdp_mid": signal.sdpMid as Any,
            "sdp_mline_index": signal.sdpMLineIndex as Any
        ]
        sendJSON(payload)
    }

    // MARK: - Private
    private func subscribe() {
        let token = KeychainService.shared.authToken ?? ""
        let payload: [String: Any] = [
            "type": "subscribe",
            "access_token": token
        ]
        sendJSON(payload)
    }

    private func sendJSON(_ dict: [String: Any]) {
        guard let data = try? JSONSerialization.data(withJSONObject: dict) else { return }
        connection?.send(content: data, completion: .contentProcessed({ _ in }))
    }

    private func handleMessage(_ data: Data) {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any],
              let type = json["type"] as? String else { return }

        Task { @MainActor in
            switch type {
            case "new_message":
                if let msgData = try? JSONSerialization.data(withJSONObject: json["payload"] as Any),
                   let msg = try? JSONDecoder().decode(MessageModel.self, from: msgData) {
                    lastReceivedMessage = msg
                }
            case "typing":
                if let chatID = json["chat_id"] as? String,
                   let userID = json["user_id"] as? String {
                    lastTypingEvent = (chatID, userID)
                }
            case "presence":
                if let userID = json["user_id"] as? String,
                   let online = json["online"] as? Bool {
                    lastOnlineStatus = (userID, online)
                }
            case "call_signal":
                lastCallSignal = CallSignal(
                    type: CallSignalType(rawValue: json["signal_type"] as? String ?? "") ?? .ringing,
                    fromUserID: json["from_user_id"] as? String ?? "",
                    chatID: json["chat_id"] as? String ?? "",
                    sdp: json["sdp"] as? String,
                    candidate: json["candidate"] as? String,
                    sdpMid: json["sdp_mid"] as? String,
                    sdpMLineIndex: json["sdp_mline_index"] as? Int32
                )
            default:
                break
            }
        }
    }

    private func scheduleReconnect() {
        guard reconnectAttempts < Constants.wsMaxReconnectAttempts else { return }
        reconnectTask?.cancel()
        reconnectTask = Task {
            try? await Task.sleep(nanoseconds: Constants.wsReconnectDelay)
            reconnectAttempts += 1
            connect()
        }
    }
}
