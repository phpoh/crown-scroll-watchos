import SwiftUI
import WatchKit

/// Main view optimized for Apple Watch Series 7 (45mm & 41mm).
/// 主界面，针对 Apple Watch Series 7（45mm 和 41mm）优化。
struct ContentView: View {
    @EnvironmentObject var wsManager: WebSocketManager
    @State private var crownValue: Double = 0
    @State private var accumulatedDelta: Double = 0
    @State private var sendTimer: Timer?

    private let velocityColors: [String: Color] = [
        "志辉轻滑": .white,
        "志辉稳滑": .cyan,
        "志辉加速": .purple,
        "志辉飞驰": .orange,
        "志辉极速": .red
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
        VStack(spacing: 12) {
            Spacer(minLength: 4)

            // Crown icon with glow effect / 表冠图标带发光效果
            ZStack {
                Circle()
                    .fill(Color.cyan.opacity(0.15))
                    .frame(width: 56, height: 56)
                Image(systemName: "crown.fill")
                    .font(.title2)
                    .foregroundColor(.cyan)
            }

            Text("志辉滚轮")
                .font(.title3)
                .fontWeight(.semibold)

            // IP input / IP 输入框
            TextField("192.168.1.100", text: $wsManager.host)
                .multilineTextAlignment(.center)
                .font(.body)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.gray.opacity(0.2))
                .cornerRadius(10)

            // Connect button / 连接按钮
            Button(action: connectAndStart) {
                HStack {
                    Image(systemName: "link")
                    Text("连接")
                }
                .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
            .controlSize(.large)

            // Status / 状态文字
            Text(wsManager.connectionStatus)
                .font(.footnote)
                .foregroundColor(.gray)

            Spacer(minLength: 4)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
    }

    // MARK: - Control View / 控制界面

    private var controlView: some View {
        VStack(spacing: 6) {
            Spacer(minLength: 2)

            // Connection indicator / 连接指示
            HStack(spacing: 6) {
                Circle()
                    .fill(Color.green)
                    .frame(width: 8, height: 8)
                    .shadow(color: .green.opacity(0.5), radius: 3)
                Text("已连接")
                    .font(.caption)
                    .foregroundColor(.green)
                Spacer()
                Text(wsManager.host)
                    .font(.system(size: 9))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
            }
            .padding(.horizontal, 4)

            // Velocity display — large center display / 速度大字显示
            VStack(spacing: 2) {
                Text(wsManager.lastVelocity)
                    .font(.system(size: 42, weight: .heavy, design: .monospaced))
                    .foregroundColor(velocityColors[wsManager.lastVelocity] ?? .white)
                    .shadow(
                        color: (velocityColors[wsManager.lastVelocity] ?? .white)
                            .opacity(0.4),
                        radius: 6
                    )
                    .animation(.easeInOut(duration: 0.2), value: wsManager.lastVelocity)
            }

            // Stats row / 数据统计行
            HStack(spacing: 0) {
                Spacer()
                statItem(label: "位置", value: "\(wsManager.lastPosition)")
                Spacer()
                statItem(label: "步长", value: "\(wsManager.lastStep)")
                Spacer()
            }

            // Divider / 分隔线
            Rectangle()
                .fill(Color.gray.opacity(0.2))
                .frame(height: 1)
                .padding(.horizontal, 16)

            // Hint + Disconnect / 提示 + 断开按钮
            HStack {
                Text("旋转表冠控制")
                    .font(.system(size: 10))
                    .foregroundColor(.secondary)
                Spacer()
                Button("断开") {
                    stopSending()
                    wsManager.disconnect()
                }
                .font(.footnote)
                .tint(.red)
            }
            .padding(.horizontal, 4)

            Spacer(minLength: 2)
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .focusable()
        .digitalCrownRotation(
            $crownValue,
            from: -100000.0,
            through: 100000.0,
            sensitivity: .high,
            isContinuous: true,
            isHapticFeedbackEnabled: true
        )
        .onChange(of: crownValue) { oldValue, newValue in
            let delta = newValue - oldValue
            accumulatedDelta += delta
        }
    }

    // MARK: - Components / 组件

    private func statItem(label: String, value: String) -> some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.system(size: 10))
                .foregroundColor(.gray)
            Text(value)
                .font(.title3)
                .fontWeight(.medium)
                .monospacedDigit()
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

            // Convert rotation to delta (scaled by 3 for sensitivity)
            // 将旋转量转为 delta（放大 3 倍）
            let delta = Int(accumulatedDelta * 3)

            // Calculate speed (0.0 ~ 1.0)
            // 计算速度 (0.0 ~ 1.0)
            let speed = min(abs(accumulatedDelta) / 0.3, 1.0)

            // Play haptic feedback sound / 播放触觉反馈音效
            WKInterfaceDevice.current().play(.click)

            wsManager.sendCrownInput(delta: delta, speed: speed)
            accumulatedDelta = 0
        }
    }

    private func stopSending() {
        sendTimer?.invalidate()
        sendTimer = nil
        accumulatedDelta = 0
        crownValue = 0
    }
}
