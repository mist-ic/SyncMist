//go:build ignore

package main

import (
	"encoding/json"
	"log"

	"github.com/gorilla/websocket"
)

func main() {
	url := "ws://localhost:8080/ws"
	conn, _, err := websocket.DefaultDialer.Dial(url, nil)
	if err != nil {
		log.Fatal(err)
	}
	defer conn.Close()

	msg := map[string]interface{}{
		"type":      "clipboard",
		"content":   "bWlzdC1pYy1zZWNyZXQtZW5jcnlwdGVkLWRhdGE=", // base64 for "mist-ic-secret-encrypted-data"
		"sender":    "test-manual",
		"encrypted": true,
	}

	payload, _ := json.Marshal(msg)
	if err := conn.WriteMessage(websocket.TextMessage, payload); err != nil {
		log.Fatal(err)
	}
	log.Println("Mock encrypted message sent")
}
