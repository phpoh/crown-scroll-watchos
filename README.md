# 👑 CrownScroll-WatchOS

> Apple Watch Digital Crown controller — turn your watch into a holographic scroll controller!
> Apple Watch 数字表冠控制器 — 把手表变成全息滚动控制器！

---

## ✨ Features / 功能

| Feature | Description | 说明 |
|---------|-------------|------|
| 🎮 Digital Crown | Rotate the crown to scroll any window on your computer | 旋转表冠控制电脑滚动 |
| ⚡ Acceleration | Speed-sensitive step calculation for inertia feel | 速度感应加速度算法，模拟惯性感 |
| 🌐 WebSocket | Low-latency real-time connection | 低延迟 WebSocket 实时通信 |
| 📊 Velocity | Live display of CRAWL → HYPERDRIVE speed levels | 实时显示 5 级速度等级 |
| 🍎 Native | Built with SwiftUI, native Apple Watch experience | 原生 SwiftUI 开发 |

---

## 🏗 Architecture / 架构

```
Apple Watch (CrownScroll)
    │
    │  Digital Crown rotation / 数字表冠旋转
    │
    ▼
WebSocket: ws://<server-ip>:3000/ws/crown
    │
    ▼
Rust Backend ([rust-api](https://github.com/phpoh/rust-api))
    │
    ▼
System-level scroll (Windows / macOS) / 系统级滚动
```

---

## 📋 Requirements / 环境要求

| Requirement | Version |
|-------------|---------|
| Apple Watch | watchOS 9.0+ |
| Mac | Xcode 14+ |
| Backend | [rust-api](https://github.com/phpoh/rust-api) running on your computer |

---

## 🚀 Setup / 安装步骤

### 1. Clone / 克隆

```bash
git clone https://github.com/phpoh/crown-scroll-watchos.git
cd crown-scroll-watchos
```

### 2. Create Xcode Project / 创建 Xcode 项目

1. Open **Xcode** → **File** → **New** → **Project**
2. Select **watchOS** → **App** → **Next**
3. Configure:
   - Product Name: `CrownScroll`
   - Interface: **SwiftUI**
   - Language: **Swift**
   - Minimum Deployment: **watchOS 9.0**
4. Save to a temporary location
5. Copy source files from this repo into the Xcode project:

| Source File | Target in Xcode |
|-------------|----------------|
| `CrownScroll/CrownScrollApp.swift` | Replace auto-generated App file / 替换自动生成的 App 文件 |
| `CrownScroll/ContentView.swift` | Replace auto-generated ContentView / 替换自动生成的 ContentView |
| `CrownScroll/Services/WebSocketManager.swift` | Create new file / 新建文件 |

### 3. Network Security / 网络安全配置

Add to your Watch App's **Info.plist**:

```xml
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

> This allows WebSocket connections to `ws://` (without TLS). / 允许 WebSocket 连接到 `ws://`（无 TLS）。

### 4. Build & Run / 编译运行

1. Connect your Apple Watch to Xcode via USB or Wi-Fi
2. Select your Apple Watch as the run destination
3. Press **⌘R** to build and install

> **Note:** WatchOS apps require a real Apple Watch device. The simulator does not support Digital Crown rotation. / WatchOS 应用需要真机测试，模拟器不支持数字表冠旋转。

---

## 📱 Usage / 使用方法

1. Start the [rust-api backend](https://github.com/phpoh/rust-api) on your computer:
   ```bash
   cargo run
   ```

2. Find your computer's local IP / 查看电脑局域网 IP:
   ```bash
   # Windows
   ipconfig
   # macOS
   ifconfig | grep inet
   ```

3. Open **CrownScroll** on your Apple Watch

4. Enter your computer's IP address / 输入电脑 IP 地址

5. Tap **连接** (Connect)

6. Rotate the Digital Crown — your computer's foreground window will scroll! / 旋转数字表冠，电脑前台窗口开始滚动！

---

## 🎮 Protocol / 通信协议

### Send / 发送

```json
{ "delta": 5, "speed": 0.3 }
```

| Field | Type | Description |
|-------|------|-------------|
| `delta` | Int | Rotation delta (positive=scroll up, negative=scroll down) / 旋转增量 |
| `speed` | Double | Rotation speed 0.0~1.0 / 旋转速度 |

### Receive / 接收

```json
{ "position": 42, "step": 8, "velocity": "STEADY" }
```

| Field | Type | Description |
|-------|------|-------------|
| `position` | Int | Current scroll position / 当前滚动位置 |
| `step` | Int | Actual step (with acceleration) / 实际步长 |
| `velocity` | String | Speed level / 速度等级 |

### Velocity Levels / 速度等级

| Step Range | Level | Color | Feel / 感觉 |
|------------|-------|-------|-------------|
| 0 ~ 5 | `CRAWL` 🐢 | ⚪ White | Slow precision / 慢速精调 |
| 6 ~ 20 | `STEADY` 🚶 | 🔵 Cyan | Steady scroll / 稳定滚动 |
| 21 ~ 50 | `BOOST` 🏍️ | 🟣 Purple | Accelerating / 加速推进 |
| 51 ~ 100 | `WARP` 🚀 | 🟠 Orange | High speed / 高速穿越 |
| 100+ | `HYPERDRIVE` ⚡ | 🔴 Red | Ludicrous speed! / 超光速！ |

---

## 📂 Project Structure / 项目结构

```
CrownScroll/
├── CrownScrollApp.swift                # App entry / 应用入口
├── ContentView.swift                    # Main UI + Digital Crown / 主界面 + 数字表冠
└── Services/
    └── WebSocketManager.swift           # WebSocket service / WebSocket 服务
```

---

## 🔧 Parameter Tuning / 参数调优

You can adjust these values in `ContentView.swift`:

```swift
// Send interval (default 0.1s) / 发送间隔（默认 0.1 秒）
Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true)

// Delta sensitivity multiplier (default 10) / Delta 灵敏度倍率（默认 10）
let delta = Int(accumulatedDelta * 10)

// Speed threshold (default 0.3, smaller = more sensitive) / 速度阈值（默认 0.3，越小越灵敏）
let speed = min(abs(accumulatedDelta) / 0.3, 1.0)
```

---

## 🔗 Related Projects / 相关项目

- **[rust-api](https://github.com/phpoh/rust-api)** — The Rust backend server that receives crown events and triggers system-level scrolling on Windows/macOS. / 接收表冠事件并触发 Windows/macOS 系统级滚动的 Rust 后端服务器。

---

## ❓ FAQ / 常见问题

### Q: Watch 连不上 WebSocket？
确保 Apple Watch 和电脑在同一 WiFi 网络。WatchOS 不支持模拟器测试 WebSocket，需要真机。

### Q: 旋转表冠没反应？
确保连接成功后界面显示 "已连接"。点击其他区域让控制界面获得焦点（focusable），表冠才能生效。

### Q: 滚动方向反了？
在 `ContentView.swift` 中将 delta 取反：`let delta = -Int(accumulatedDelta * 10)`

### Q: 如何调试？
Xcode 连接 Apple Watch 真机，查看控制台日志输出。

---

## 📜 License

MIT License
