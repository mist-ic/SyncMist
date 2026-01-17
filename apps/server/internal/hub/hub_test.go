package hub

import (
	"encoding/json"
	"net/http"
	"net/http/httptest"
	"strings"
	"testing"
	"time"

	"github.com/gorilla/websocket"
)

var upgrader = websocket.Upgrader{
	ReadBufferSize:  1024,
	WriteBufferSize: 1024,
}

func TestHubIntegration(t *testing.T) {
	h := NewHub()
	go h.Run()

	server := httptest.NewServer(http.HandlerFunc(func(w http.ResponseWriter, r *http.Request) {
		conn, err := upgrader.Upgrade(w, r, nil)
		if err != nil {
			return
		}
		client := NewClient(h, conn, "test-device")
		h.register <- client

		go client.WritePump()
		client.ReadPump()
	}))
	defer server.Close()

	wsURL := "ws" + strings.TrimPrefix(server.URL, "http")

	// Create two clients
	dialer := websocket.Dialer{}
	conn1, _, err := dialer.Dial(wsURL, nil)
	if err != nil {
		t.Fatalf("Failed to dial 1: %v", err)
	}
	defer conn1.Close()

	conn2, _, err := dialer.Dial(wsURL, nil)
	if err != nil {
		t.Fatalf("Failed to dial 2: %v", err)
	}
	defer conn2.Close()

	// Wait for registration
	time.Sleep(100 * time.Millisecond)

	msg := Message{
		Type:    "test",
		Content: "hello from client 1",
		Sender:  "c1",
	}
	payload, _ := json.Marshal(msg)

	// Send from conn1
	if err := conn1.WriteMessage(websocket.TextMessage, payload); err != nil {
		t.Fatalf("Failed to write: %v", err)
	}

	// conn2 should receive it
	done := make(chan struct{})
	go func() {
		_, received, err := conn2.ReadMessage()
		if err != nil {
			t.Errorf("conn2 read error: %v", err)
			return
		}
		if string(received) != string(payload) {
			t.Errorf("Expected %s, got %s", string(payload), string(received))
		}
		close(done)
	}()

	select {
	case <-done:
		// Success
	case <-time.After(500 * time.Millisecond):
		t.Error("conn2 timed out waiting for broadcast")
	}

	// conn1 should NOT receive it (wait a bit to be sure)
	conn1.SetReadDeadline(time.Now().Add(100 * time.Millisecond))
	_, _, err = conn1.ReadMessage()
	if err == nil {
		t.Error("conn1 (sender) should NOT have received its own message")
	}
}
