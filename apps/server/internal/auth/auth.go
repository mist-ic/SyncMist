package auth

import (
	"fmt"
	"os"
	"time"

	"github.com/golang-jwt/jwt/v5"
)

// Claims represents the JWT claims
type Claims struct {
	DeviceID string `json:"device_id"`
	jwt.RegisteredClaims
}

// getJWTSecret retrieves the JWT secret from environment or returns a default for development
func getJWTSecret() []byte {
	secret := os.Getenv("JWT_SECRET")
	if secret == "" {
		// Default secret for development - should be overridden in production
		return []byte("dev-secret-change-in-production")
	}
	return []byte(secret)
}

// GenerateToken generates a JWT token for a given device ID
func GenerateToken(deviceID string) (string, error) {
	if deviceID == "" {
		return "", fmt.Errorf("device ID cannot be empty")
	}

	// Create claims with device ID and expiration
	claims := Claims{
		DeviceID: deviceID,
		RegisteredClaims: jwt.RegisteredClaims{
			ExpiresAt: jwt.NewNumericDate(time.Now().Add(24 * time.Hour)),
			IssuedAt:  jwt.NewNumericDate(time.Now()),
		},
	}

	// Create token with claims
	token := jwt.NewWithClaims(jwt.SigningMethodHS256, claims)

	// Sign and get the complete encoded token as a string
	tokenString, err := token.SignedString(getJWTSecret())
	if err != nil {
		return "", fmt.Errorf("failed to sign token: %w", err)
	}

	return tokenString, nil
}

// ValidateToken validates a JWT token and returns the device ID
func ValidateToken(tokenString string) (string, error) {
	if tokenString == "" {
		return "", fmt.Errorf("token cannot be empty")
	}

	// Parse the token
	token, err := jwt.ParseWithClaims(tokenString, &Claims{}, func(token *jwt.Token) (interface{}, error) {
		// Validate the signing method
		if _, ok := token.Method.(*jwt.SigningMethodHMAC); !ok {
			return nil, fmt.Errorf("unexpected signing method: %v", token.Header["alg"])
		}
		return getJWTSecret(), nil
	})

	if err != nil {
		return "", fmt.Errorf("failed to parse token: %w", err)
	}

	// Extract claims
	if claims, ok := token.Claims.(*Claims); ok && token.Valid {
		return claims.DeviceID, nil
	}

	return "", fmt.Errorf("invalid token claims")
}
