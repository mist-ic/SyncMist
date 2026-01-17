package main

import (
	"encoding/json"
	"log/slog"
	"net/http"
	"os"

	"github.com/mist-ic/SyncMist/apps/server/internal/auth"
	"github.com/mist-ic/SyncMist/apps/server/internal/hub"

	"github.com/gorilla/websocket"
)

var upgrader = websocket.Upgrader{
	ReadBufferSize:  1024,
	WriteBufferSize: 1024,
	CheckOrigin: func(r *http.Request) bool {
		// Allow connections from any origin (will secure in production)
		return true
	},
}

func serveWs(h *hub.Hub, w http.ResponseWriter, r *http.Request) {
	// Extract and validate JWT token from query parameter
	token := r.URL.Query().Get("token")
	if token == "" {
		slog.Warn("WebSocket connection rejected: missing token")
		http.Error(w, "Unauthorized: missing token", http.StatusUnauthorized)
		return
	}

	// Validate token and extract device ID
	deviceID, err := auth.ValidateToken(token)
	if err != nil {
		slog.Warn("WebSocket connection rejected: invalid token", "error", err)
		http.Error(w, "Unauthorized: invalid token", http.StatusUnauthorized)
		return
	}

	conn, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		slog.Error("WebSocket upgrade failed", "error", err)
		return
	}

	client := hub.NewClient(h, conn, deviceID)
	h.Register(client)

	// Start read and write pumps in separate goroutines
	go client.WritePump()
	go client.ReadPump()
}

func main() {
	// Configure structured logging
	logger := slog.New(slog.NewTextHandler(os.Stdout, &slog.HandlerOptions{
		Level: slog.LevelDebug,
	}))
	slog.SetDefault(logger)

	// Create and start the hub
	h := hub.NewHub()
	go h.Run()

	// Health check endpoint
	http.HandleFunc("/health", func(w http.ResponseWriter, r *http.Request) {
		w.WriteHeader(http.StatusOK)
		w.Write([]byte("OK"))
	})

	// Register endpoint - issues JWT tokens for device IDs
	http.HandleFunc("/register", func(w http.ResponseWriter, r *http.Request) {
		if r.Method != http.MethodPost {
			http.Error(w, "Method not allowed", http.StatusMethodNotAllowed)
			return
		}

		// Parse request body
		var req struct {
			DeviceID string `json:"device_id"`
		}
		if err := json.NewDecoder(r.Body).Decode(&req); err != nil {
			slog.Error("Failed to parse register request", "error", err)
			http.Error(w, "Bad request", http.StatusBadRequest)
			return
		}

		if req.DeviceID == "" {
			http.Error(w, "device_id is required", http.StatusBadRequest)
			return
		}

		// Generate JWT token
		token, err := auth.GenerateToken(req.DeviceID)
		if err != nil {
			slog.Error("Failed to generate token", "error", err, "device_id", req.DeviceID)
			http.Error(w, "Internal server error", http.StatusInternalServerError)
			return
		}

		// Return token
		slog.Info("Token generated", "device_id", req.DeviceID)
		w.Header().Set("Content-Type", "application/json")
		json.NewEncoder(w).Encode(map[string]string{"token": token})
	})

	// WebSocket endpoint
	http.HandleFunc("/ws", func(w http.ResponseWriter, r *http.Request) {
		serveWs(h, w, r)
	})

	// Get port from environment or default
	port := os.Getenv("PORT")
	if port == "" {
		port = "8080"
	}

	slog.Info("Server starting", "port", port)
	if err := http.ListenAndServe(":"+port, nil); err != nil {
		slog.Error("Server failed", "error", err)
		os.Exit(1)
	}
}
