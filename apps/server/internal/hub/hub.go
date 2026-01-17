package hub

import (
	"encoding/json"
	"log/slog"
)

// Hub maintains the set of active clients and broadcasts messages to the clients.
type Hub struct {
	// Registered clients
	clients map[*Client]bool

	// Device ID to client mapping
	deviceMap map[string]*Client

	// Inbound messages from the clients
	broadcast chan broadcastMessage

	// Register requests from the clients
	register chan *Client

	// Unregister requests from clients
	unregister chan *Client
}

// NewHub creates a new Hub instance
func NewHub() *Hub {
	return &Hub{
		broadcast:  make(chan broadcastMessage, 256),
		register:   make(chan *Client),
		unregister: make(chan *Client),
		clients:    make(map[*Client]bool),
		deviceMap:  make(map[string]*Client),
	}
}

// Run starts the hub's main loop to handle client registration, unregistration, and broadcasting
func (h *Hub) Run() {
	for {
		select {
		case client := <-h.register:
			h.clients[client] = true
			h.deviceMap[client.deviceID] = client
			slog.Info("Client registered", "device_id", client.deviceID, "address", client.conn.RemoteAddr(), "total_clients", len(h.clients))

		case client := <-h.unregister:
			if _, ok := h.clients[client]; ok {
				delete(h.clients, client)
				delete(h.deviceMap, client.deviceID)
				close(client.send)
				slog.Info("Client unregistered", "device_id", client.deviceID, "address", client.conn.RemoteAddr(), "total_clients", len(h.clients))
			}

		case bm := <-h.broadcast:
			var msg Message
			if err := json.Unmarshal(bm.payload, &msg); err != nil {
				slog.Error("Failed to parse JSON message", "error", err, "payload", string(bm.payload))
				continue
			}

			// Truncate content for logging
			displayContent := msg.Content
			if len(displayContent) > 50 {
				displayContent = displayContent[:47] + "..."
			}
			slog.Info("Broadcasting message", "type", msg.Type, "content", displayContent, "sender_device_id", bm.sender.deviceID)

			for client := range h.clients {
				// Broadcast to ALL clients except sender (to avoid echo)
				if client == bm.sender {
					continue
				}

				select {
				case client.send <- bm.payload:
					// Message sent successfully
				default:
					// Client's send buffer is full, assume client is dead or stuck
					close(client.send)
					delete(h.clients, client)
					delete(h.deviceMap, client.deviceID)
					slog.Warn("Removed stuck client", "device_id", client.deviceID, "address", client.conn.RemoteAddr())
				}
			}
		}
	}
}

// Register adds a client to the hub
func (h *Hub) Register(client *Client) {
	h.register <- client
}
