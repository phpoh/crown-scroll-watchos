import Foundation

/// HTTP-based crown controller — uses POST instead of WebSocket to bypass VPN blocking.
/// 基于 HTTP 的表冠控制器 — 用 POST 替代 WebSocket 绕过 VPN 拦截。
class WebSocketManager: ObservableObject {
    @Published var isConnected = false
    @Published var connectionStatus = "未连接"
    @Published var lastVelocity = "--"
    @Published var lastPosition = 0
    @Published var lastStep = 0
    @Published var host = "192.168.1.100"

    // MARK: - Connection (test reachability)

    func connect() {
        let cleanHost = host.trimmingCharacters(in: .whitespaces)
        disconnect()
        DispatchQueue.main.async { self.connectionStatus = "连接中..." }

        let testUrl = URL(string: "http://\(cleanHost):3000/screenshot")!
        var request = URLRequest(url: testUrl)
        request.timeoutInterval = 5

        URLSession.shared.dataTask(with: request) { [weak self] _, response, error in
            DispatchQueue.main.async {
                guard let self = self else { return }
                if let error = error {
                    self.connectionStatus = "连接失败: \(error.localizedDescription)"
                } else {
                    self.isConnected = true
                    self.connectionStatus = "已连接"
                }
            }
        }.resume()
    }

    func disconnect() {
        isConnected = false
        connectionStatus = "未连接"
        lastVelocity = "--"
        lastPosition = 0
        lastStep = 0
    }

    // MARK: - Send (HTTP POST)

    func sendCrownInput(delta: Int, speed: Double) {
        let cleanHost = host.trimmingCharacters(in: .whitespaces)
        guard let url = URL(string: "http://\(cleanHost):3000/crown") else { return }

        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.timeoutInterval = 2
        request.httpBody = try? JSONSerialization.data(withJSONObject: [
            "delta": delta,
            "speed": speed
        ])

        URLSession.shared.dataTask(with: request) { [weak self] data, _, error in
            guard let data = data, error == nil else {
                if let error = error {
                    print("POST error: \(error)")
                }
                return
            }
            self?.parseResponse(data)
        }.resume()
    }

    private func parseResponse(_ data: Data) {
        guard let json = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else { return }

        DispatchQueue.main.async {
            if let position = json["position"] as? Int { self.lastPosition = position }
            if let step = json["step"] as? Int { self.lastStep = step }
            if let velocity = json["velocity"] as? String { self.lastVelocity = velocity }
        }
    }
}
