import Foundation

/// WebSocket manager — connects to rust-api backend and sends crown rotation data.
/// WebSocket 管理器 — 连接 rust-api 后端，发送表冠旋转数据。
class WebSocketManager: ObservableObject {
    @Published var isConnected = false
    @Published var connectionStatus = "未连接"
    @Published var lastVelocity = "--"
    @Published var lastPosition = 0
    @Published var lastStep = 0
    @Published var host = "192.168.1.100"

    private var webSocketTask: URLSessionWebSocketTask?
    private var urlSession: URLSession?

    // MARK: - Connection

    /// Connect to the rust-api WebSocket server.
    /// 连接 rust-api WebSocket 服务器。
    func connect() {
        let cleanHost = host.trimmingCharacters(in: .whitespaces)
        let urlString = "ws://\(cleanHost):3000/ws/crown"
        guard let url = URL(string: urlString) else {
            DispatchQueue.main.async { self.connectionStatus = "地址无效" }
            return
        }

        disconnect()
        DispatchQueue.main.async { self.connectionStatus = "连接中..." }

        urlSession = URLSession(configuration: .default)
        webSocketTask = urlSession?.webSocketTask(with: url)
        webSocketTask?.resume()

        // Verify connection after delay / 延迟验证连接
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) { [weak self] in
            guard let self = self else { return }
            if self.webSocketTask?.state == .running {
                self.isConnected = true
                self.connectionStatus = "已连接"
                self.startReceiving()
            } else {
                self.connectionStatus = "连接失败"
            }
        }
    }

    /// Disconnect from server.
    /// 断开连接。
    func disconnect() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        webSocketTask = nil
        urlSession = nil
        isConnected = false
        connectionStatus = "未连接"
        lastVelocity = "--"
        lastPosition = 0
        lastStep = 0
    }

    // MARK: - Send

    /// Send crown rotation data to the server.
    /// 发送表冠旋转数据到服务器。
    func sendCrownInput(delta: Int, speed: Double) {
        let message: [String: Any] = [
            "delta": delta,
            "speed": speed
        ]

        guard let data = try? JSONSerialization.data(withJSONObject: message),
              let jsonString = String(data: data, encoding: .utf8) else { return }

        webSocketTask?.send(.string(jsonString)) { [weak self] error in
            if let _ = error {
                DispatchQueue.main.async {
                    self?.isConnected = false
                    self?.connectionStatus = "连接断开"
                }
            }
        }
    }

    // MARK: - Receive

    private func startReceiving() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .success(let message):
                if case .string(let text) = message {
                    self?.parseResponse(text)
                }
                self?.startReceiving()
            case .failure:
                DispatchQueue.main.async {
                    self?.isConnected = false
                    self?.connectionStatus = "连接断开"
                }
            }
        }
    }

    private func parseResponse(_ text: String) {
        guard let data = text.data(using: .utf8),
              let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return }

        DispatchQueue.main.async {
            if let position = json["position"] as? Int { self.lastPosition = position }
            if let step = json["step"] as? Int { self.lastStep = step }
            if let velocity = json["velocity"] as? String { self.lastVelocity = velocity }
        }
    }
}
