import SwiftUI

struct ContentView: View {
    @EnvironmentObject var wsManager: WebSocketManager
    @State private var crownValue: Double = 0
    @State private var lastCrownValue: Double = 0
    @State private var accumulatedDelta: Double = 0
    @State private var sendTimer: Timer?

    private let velocityColors: [String: Color] = [
        "CRAWL": .white,
        "STEADY": .cyan,
        "BOOST": .purple,
        "WARP": .orange,
        "HYPERDRIVE": .red
    ]

    var body: some View {
        ZStack {
            if wsManager.isConnected {
                controlView
            } else {
                setupView
            }
        }
    }

    // MARK: - Setup View / 连接界面

    private var setupView: some View {
        VStack(spacing: 14) {
            Image(systemName: "crown.fill")
                .font(.title)
                .foregroundColor(.cyan)

            Text("CrownScroll")
                .font(.headline)

            TextField("服务器 IP", text: $wsManager.host)
                .multilineTextAlignment(.center)
                .font(.caption)
                .padding(8)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(8)

            Button(action: connectAndStart) {
                Text("连接")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)

            Text(wsManager.connectionStatus)
                .font(.system(size: 10))
                .foregroundColor(.gray)
        }
        .padding()
    }

    // MARK: - Control View / 控制界面

    private var controlView: some View {
        VStack(spacing: 10) {
            // Connection indicator / 连接指示
            HStack(spacing: 4) {
                Circle()
                    .fill(Color.green)
                    .frame(width: 6, height: 6)
                Text("已连接")
                    .font(.system(size: 9))
                    .foregroundColor(.green)
            }

            // Velocity display / 速度显示
            Text(wsManager.lastVelocity)
                .font(.system(size: 36, weight: .bold, design: .monospaced))
                .foregroundColor(velocityColors[wsManager.lastVelocity] ?? .white)

            // Stats / 数据统计
            HStack(spacing: 20) {
                VStack(spacing: 2) {
                    Text("位置")
                        .font(.system(size: 9))
                        .foregroundColor(.gray)
                    Text("\(wsManager.lastPosition)")
                        .font(.caption)
                        .monospacedDigit()
                }
                VStack(spacing: 2) {
                    Text("步长")
                        .font(.system(size: 9))
                        .foregroundColor(.gray)
                    Text("\(wsManager.lastStep)")
                        .font(.caption)
                        .monospacedDigit()
                }
            }

            Text("旋转表冠控制滚动")
                .font(.system(size: 9))
                .foregroundColor(.secondary)

            Button("断开连接") {
                stopSending()
                wsManager.disconnect()
            }
            .font(.system(size: 10))
            .tint(.red)
        }
        .padding()
        .focusable()
        .digitalCrownRotation(
            $crownValue,
            from: -100000.0,
            through: 100000.0,
            sensitivity: .high,
            isContinuous: true,
            isHapticFeedbackEnabled: true
        )
        .onChange(of: crownValue) { newValue in
            let delta = newValue - lastCrownValue
            lastCrownValue = newValue
            accumulatedDelta += delta
        }
    }

    // MARK: - Timer / 定时发送

    private func connectAndStart() {
        wsManager.connect()
        // Wait for connection, then start send loop / 等待连接后启动发送循环
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            if wsManager.isConnected {
                startSending()
            }
        }
    }

    private func startSending() {
        sendTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { _ in
            guard abs(accumulatedDelta) > 0.01 else { return }

            // Convert rotation to delta (scaled by 10 for sensitivity)
            // 将旋转量转为 delta（放大 10 倍增加灵敏度）
            let delta = Int(accumulatedDelta * 10)

            // Calculate speed (0.0 ~ 1.0)
            // 计算速度 (0.0 ~ 1.0)
            let speed = min(abs(accumulatedDelta) / 0.3, 1.0)

            wsManager.sendCrownInput(delta: delta, speed: speed)
            accumulatedDelta = 0
        }
    }

    private func stopSending() {
        sendTimer?.invalidate()
        sendTimer = nil
        accumulatedDelta = 0
        crownValue = 0
        lastCrownValue = 0
    }
}
