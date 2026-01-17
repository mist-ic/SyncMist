# SyncMist

**Universal Clipboard Sync** – Copy anywhere, paste everywhere.

> 🏆 **Hackathon Branch** – Cross-platform, cross-network clipboard synchronization

## 🎯 Problem Statement

Build a clipboard sync system that:

- ✅ Works across **different networks** (not just same Wi-Fi)
- ✅ **End-to-end encrypted** – clipboard data never touches servers
- ✅ **P2P data transfer** with signaling for discovery
- ✅ **Cross-platform** – Windows, Linux, Android
- ✅ **Offline queuing** – sync when reconnected

## ✨ Features

| Feature | Status |
|---------|--------|
| Cross-platform (Windows/Linux/Android) | ✅ |
| E2E Encryption (AES-256-GCM) | ✅ |
| mDNS Discovery (LAN) | ✅ |
| QUIC Transport (P2P) | ✅ |
| Device Pairing (QR Code) | ✅ |
| Clipboard History | 🔜 |
| NAT Traversal (Internet) | 🔜 |

## 📦 Tech Stack

| Layer | Technology |
|-------|------------|
| **UI** | Flutter |
| **Services** | Dart (Riverpod) |
| **Core** | Rust (quinn, mdns-sd, aes-gcm) |
| **FFI** | flutter_rust_bridge |
| **Build** | Moon monorepo |

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────┐
│                     Flutter UI                          │
│  (Home Screen, Peer List, Network Graph, Status Badge)  │
├─────────────────────────────────────────────────────────┤
│                   Flutter Services                       │
│  (SyncCoordinator, P2PService, DiscoveryService)        │
├─────────────────────────────────────────────────────────┤
│                     Rust Core (FFI)                      │
│  ┌─────────────┐  ┌─────────────┐  ┌─────────────┐      │
│  │ QUIC        │  │ mDNS        │  │ AES-256-GCM │      │
│  │ Transport   │  │ Discovery   │  │ Crypto      │      │
│  └─────────────┘  └─────────────┘  └─────────────┘      │
└─────────────────────────────────────────────────────────┘
```

## 🚀 Quick Start

### Prerequisites

- [Flutter](https://flutter.dev) 3.22+
- [Rust](https://rustup.rs) stable
- [Moon](https://moonrepo.dev) (optional)

### Build & Run

```bash
# Clone
git clone https://github.com/mist-ic/SyncMist.git
cd SyncMist
git checkout Hackathon

# Rust core
cd packages/rust_core
cargo build --release
cargo test  # 23 tests

# Flutter app
cd ../../apps/flutter_app
flutter pub get
flutter run -d windows  # or linux, android
```

### Moon Commands (Optional)

```bash
moon run flutter_app:dev          # Run app
moon run flutter_app:analyze      # Lint
moon run flutter_app:build-windows # Build
```

## 🔒 Security

| Aspect | Implementation |
|--------|----------------|
| **Encryption** | AES-256-GCM (Rust) |
| **Key Exchange** | TOFU (Trust On First Use) |
| **Transport** | QUIC with TLS 1.3 |
| **Data Storage** | Local only – never on servers |

## 🧪 Testing Guide

1. Run app on 2+ devices (same network for LAN, or paired for internet)
2. Devices auto-discover via mDNS
3. Click link icon to connect
4. Copy on Device A → paste on Device B

```bash
# Verify Rust tests pass
cd packages/rust_core && cargo test

# Verify Flutter analyzes clean
cd apps/flutter_app && flutter analyze
```

## 👥 Team

| Member | Role | Tasks |
|--------|------|-------|
| **Praveen** | Rust Core | QUIC, mDNS, Crypto, FFI |
| **Bish** | Services | P2P, Discovery, Sync Coordinator |
| **Dhruv** | UI | Widgets, Home Screen, Integration |

## 📁 Project Structure

```
SyncMist/
├── .moon/                    # Moon monorepo config
├── apps/
│   └── flutter_app/          # Flutter client
│       ├── lib/
│       │   ├── ui/           # Widgets & screens
│       │   ├── services/     # Business logic
│       │   ├── core/         # Interfaces
│       │   └── src/rust/     # FFI bindings
│       └── moon.yml
├── packages/
│   └── rust_core/            # Rust library
│       ├── src/
│       │   ├── transport/    # QUIC
│       │   ├── discovery/    # mDNS
│       │   └── crypto.rs     # AES-256-GCM
│       └── moon.yml
└── Internal/                 # Team docs (gitignored)
```

## 📄 License

MIT License – see [LICENSE](LICENSE)

---

**Built for Hackathon** – Universal Clipboard Sync
