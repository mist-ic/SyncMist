//! Cryptographic functions for SyncMist
//! 
//! Provides AES-256-GCM encryption/decryption and key generation.

use aes_gcm::{
    aead::{Aead, KeyInit},
    Aes256Gcm, Nonce,
};
use rand::{rngs::OsRng, RngCore};

const NONCE_SIZE: usize = 12;
const KEY_SIZE: usize = 32;

/// Generate a random 256-bit encryption key
#[flutter_rust_bridge::frb(sync)]
pub fn generate_key() -> Vec<u8> {
    let mut key = vec![0u8; KEY_SIZE];
    OsRng.fill_bytes(&mut key);
    key
}

/// Encrypt plaintext using AES-256-GCM
/// 
/// Returns: nonce (12 bytes) || ciphertext || tag (16 bytes)
#[flutter_rust_bridge::frb(sync)]
pub fn encrypt_text(plaintext: String, key: Vec<u8>) -> Result<Vec<u8>, String> {
    if key.len() != KEY_SIZE {
        return Err(format!("Key must be {} bytes, got {}", KEY_SIZE, key.len()));
    }

    let cipher = Aes256Gcm::new_from_slice(&key)
        .map_err(|e| format!("Failed to create cipher: {}", e))?;

    // Generate random nonce
    let mut nonce_bytes = [0u8; NONCE_SIZE];
    OsRng.fill_bytes(&mut nonce_bytes);
    let nonce = Nonce::from_slice(&nonce_bytes);

    // Encrypt
    let ciphertext = cipher
        .encrypt(nonce, plaintext.as_bytes())
        .map_err(|e| format!("Encryption failed: {}", e))?;

    // Prepend nonce to ciphertext
    let mut result = nonce_bytes.to_vec();
    result.extend(ciphertext);
    Ok(result)
}

/// Decrypt ciphertext using AES-256-GCM
/// 
/// Expects: nonce (12 bytes) || ciphertext || tag (16 bytes)
#[flutter_rust_bridge::frb(sync)]
pub fn decrypt_text(ciphertext: Vec<u8>, key: Vec<u8>) -> Result<String, String> {
    if key.len() != KEY_SIZE {
        return Err(format!("Key must be {} bytes, got {}", KEY_SIZE, key.len()));
    }
    if ciphertext.len() < NONCE_SIZE {
        return Err("Ciphertext too short".into());
    }

    let cipher = Aes256Gcm::new_from_slice(&key)
        .map_err(|e| format!("Failed to create cipher: {}", e))?;

    // Extract nonce and encrypted data
    let nonce = Nonce::from_slice(&ciphertext[..NONCE_SIZE]);
    let encrypted = &ciphertext[NONCE_SIZE..];

    // Decrypt
    let plaintext = cipher
        .decrypt(nonce, encrypted)
        .map_err(|e| format!("Decryption failed: {}", e))?;

    String::from_utf8(plaintext)
        .map_err(|e| format!("Invalid UTF-8: {}", e))
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_encrypt_decrypt_roundtrip() {
        let key = generate_key();
        let original = "Hello, World! 🌍".to_string();

        let encrypted = encrypt_text(original.clone(), key.clone()).unwrap();
        let decrypted = decrypt_text(encrypted, key).unwrap();

        assert_eq!(original, decrypted);
    }

    #[test]
    fn test_different_keys_fail() {
        let key1 = generate_key();
        let key2 = generate_key();
        let original = "Secret message".to_string();

        let encrypted = encrypt_text(original, key1).unwrap();
        let result = decrypt_text(encrypted, key2);

        assert!(result.is_err());
    }

    #[test]
    fn test_invalid_key_length() {
        let short_key = vec![0u8; 16]; // Should be 32
        let result = encrypt_text("test".to_string(), short_key);

        assert!(result.is_err());
        assert!(result.unwrap_err().contains("32 bytes"));
    }
}
