# SyncMist

**Pure P2P Clipboard Sync** - Copy anywhere, paste everywhere. No servers, no cloud.

## 🎯 Hackathon Version

This is the hackathon implementation with **pure peer-to-peer architecture** - zero server dependency.

## 🚀 Features

- **Pure P2P**: Direct device-to-device sync via QUIC protocol
- **Zero Server**: No cloud, no relay, no data collection
- **End-to-End Encryption**: AES-256-GCM encryption in Rust
- **LAN Discovery**: Automatic peer finding via mDNS
- **Cross-Platform**: Windows, Linux, macOS, Android, iOS
- **Offline-First**: Works completely without internet

## 📦 Tech Stack

| Component | Technology |
|-----------|------------|
| **Client** | Flutter |
| **Core** | Rust (QUIC + mDNS + Crypto) |
| **Transport** | QUIC (quinn) |
| **Discovery** | mDNS (mdns-sd) |
| **Encryption** | AES-256-GCM |
| **FFI** | flutter_rust_bridge |

## 🏗️ Project Structure

```
SyncMist/
├── apps/
│   └── flutter_app/          # Cross-platform Flutter UI
└── packages/
    └── rust_core/            # Rust P2P + crypto core
        ├── src/
        │   ├── transport/    # QUIC transport layer
        │   ├── discovery/    # mDNS discovery
        │   └── crypto.rs     # AES-256-GCM encryption
```

## 🛠️ Development Setup

### Prerequisites

- [Flutter](https://flutter.dev) - UI framework (3.29+)
- [Rust](https://rustup.rs) - Native code (stable)
- [flutter_rust_bridge_codegen](https://cjycode.com/flutter_rust_bridge/) - FFI generator

### Quick Start

```bash
# Clone the repository
git clone https://github.com/mist-ic/SyncMist.git
cd SyncMist

# Build Rust core
cd packages/rust_core
cargo build
cargo test

# Generate FFI bindings
cd apps/flutter_app
flutter_rust_bridge_codegen generate

# Run Flutter app
flutter pub get
flutter run -d windows  # or linux, macos, android, ios
```

## 🔒 Security Architecture

1. **Trust On First Use (TOFU)**: Self-signed certificates for QUIC
2. **Future**: QR code pairing with certificate fingerprint pinning
3. **AES-256-GCM**: All clipboard data encrypted before transmission
4. **No Server**: Data never leaves your local network
5. **Open Source**: Audit the code yourself

## 🌐 Network Architecture

```
┌─────────────┐              ┌─────────────┐
│  Device A   │◄────QUIC────►│  Device B   │
│             │   encrypted  │             │
│ mDNS Beacon │              │ mDNS Scan   │
└─────────────┘              └─────────────┘
       │                            │
       └────────Local Network───────┘
            (no internet needed)
```

## 📝 Development Commands

### Rust Core

```bash
cd packages/rust_core
cargo build          # Build library
cargo test           # Run unit tests
cargo clean          # Clean build artifacts
```

### Flutter App

```bash
cd apps/flutter_app
flutter pub get                           # Install dependencies
flutter_rust_bridge_codegen generate      # Regenerate FFI bindings
flutter analyze                           # Lint code
flutter test                              # Run tests
flutter run -d windows                    # Run on Windows
```

## 🧪 Testing

Two devices on the same local network:

1. Launch SyncMist on both devices
2. They auto-discover each other via mDNS
3. Copy text on Device A → appears on Device B
4. Copy text on Device B → appears on Device A

## 📄 License

MIT License - see [LICENSE](LICENSE) for details.

---

**Hackathon Project** - Pure P2P clipboard sync with zero servers
