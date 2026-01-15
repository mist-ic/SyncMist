# SyncMist 🌫️

**Universal Clipboard Sync** - Copy anywhere, paste everywhere.

[![CI](https://github.com/your-username/syncmist/actions/workflows/ci.yml/badge.svg)](https://github.com/your-username/syncmist/actions/workflows/ci.yml)

## 🚀 Features

- **Cross-Platform**: Windows, Linux, macOS, Android (iOS coming soon)
- **End-to-End Encryption**: AES-256-GCM encryption in Rust
- **Real-Time Sync**: WebSocket-based instant clipboard sharing
- **Clipboard History**: Search and reuse past clips (CRDT-powered)
- **LAN Discovery**: Direct P2P sync on same network
- **Semantic Clipboard**: Smart detection of URLs, colors, emails

## 📦 Tech Stack

| Component | Technology |
|-----------|------------|
| **Client** | Flutter + Rust Core |
| **Server** | Go + gorilla/websocket |
| **Encryption** | AES-256-GCM (Rust) |
| **Build System** | Moon (moonrepo) |
| **Package Manager** | Bun |

## 🏗️ Project Structure

```
SyncMist/
├── .moon/                    # Moon workspace config
├── apps/
│   ├── flutter_app/          # Cross-platform Flutter client
│   └── server/               # Go WebSocket relay server
├── packages/
│   └── rust_core/            # Rust encryption & CRDT library
└── docs/                     # Documentation
```

## 🛠️ Development Setup

### Prerequisites

- [Moon](https://moonrepo.dev/docs/install) - Build orchestration
- [Bun](https://bun.sh) - JavaScript runtime
- [Flutter](https://flutter.dev) - UI framework (3.16+)
- [Go](https://go.dev) - Server (1.21+)
- [Rust](https://rustup.rs) - Native code (stable)

### Quick Start

```bash
# Clone the repository
git clone https://github.com/your-username/syncmist.git
cd syncmist

# Install Moon (if not already installed)
curl -fsSL https://moonrepo.dev/install/moon.sh | bash

# Run all builds
moon run :build

# Start development
moon run server:dev    # Start Go server
moon run flutter_app:dev  # Start Flutter app
```

## 📋 Moon Commands

| Command | Description |
|---------|-------------|
| `moon run :build` | Build all projects |
| `moon run :test` | Run all tests |
| `moon run server:dev` | Start Go server in dev mode |
| `moon run flutter_app:dev` | Start Flutter app |
| `moon run rust_core:test` | Run Rust tests |
| `moon check` | Validate configuration |
| `moon project-graph` | Visualize dependencies |

## 🔒 Security

- All clipboard data is encrypted before leaving your device
- X25519 key exchange for secure device pairing
- No plaintext ever reaches the server
- Open source - audit the code yourself

## 📄 License

MIT License - see [LICENSE](LICENSE) for details.

---

Built with ❤️ for the hackathon
