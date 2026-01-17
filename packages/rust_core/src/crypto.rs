//! Cryptographic functions for SyncMist
//! 
//! Provides AES-256-GCM encryption/decryption and key generation.

use aes_gcm::{
    aead::{Aead, KeyInit},
    Aes256Gcm, Nonce,
};
use rand::{rngs::OsRng, RngCore};
use x25519_dalek::{PublicKey, StaticSecret};

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

/// Generate an X25519 keypair for device pairing
/// 
/// Returns: (secret_key, public_key) as 32-byte vectors
#[flutter_rust_bridge::frb(sync)]
pub fn generate_keypair() -> (Vec<u8>, Vec<u8>) {
    let secret = StaticSecret::random_from_rng(OsRng);
    let public = PublicKey::from(&secret);
    (secret.to_bytes().to_vec(), public.to_bytes().to_vec())
}

/// Derive shared secret using X25519 Diffie-Hellman
/// 
/// Takes your secret key and their public key, returns a 32-byte shared secret
/// that can be used as an AES-256 encryption key
#[flutter_rust_bridge::frb(sync)]
pub fn derive_shared_secret(my_secret: Vec<u8>, their_public: Vec<u8>) -> Result<Vec<u8>, String> {
    if my_secret.len() != 32 {
        return Err(format!("Secret key must be 32 bytes, got {}", my_secret.len()));
    }
    if their_public.len() != 32 {
        return Err(format!("Public key must be 32 bytes, got {}", their_public.len()));
    }

    // Convert vectors to fixed-size arrays
    let secret_bytes: [u8; 32] = my_secret.try_into()
        .map_err(|_| "Failed to convert secret key")?;
    let public_bytes: [u8; 32] = their_public.try_into()
        .map_err(|_| "Failed to convert public key")?;

    let secret = StaticSecret::from(secret_bytes);
    let their_public_key = PublicKey::from(public_bytes);

    // Perform Diffie-Hellman key exchange
    let shared_secret = secret.diffie_hellman(&their_public_key);
    
    Ok(shared_secret.as_bytes().to_vec())
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

    #[test]
    fn test_x25519_keypair_generation() {
        let (secret, public) = generate_keypair();
        
        assert_eq!(secret.len(), 32);
        assert_eq!(public.len(), 32);
        
        // Generate another keypair - should be different
        let (secret2, public2) = generate_keypair();
        assert_ne!(secret, secret2);
        assert_ne!(public, public2);
    }

    #[test]
    fn test_x25519_shared_secret_derivation() {
        // Alice generates keypair
        let (alice_secret, alice_public) = generate_keypair();
        
        // Bob generates keypair
        let (bob_secret, bob_public) = generate_keypair();
        
        // Alice derives shared secret using her secret and Bob's public
        let alice_shared = derive_shared_secret(alice_secret.clone(), bob_public.clone()).unwrap();
        
        // Bob derives shared secret using his secret and Alice's public
        let bob_shared = derive_shared_secret(bob_secret.clone(), alice_public.clone()).unwrap();
        
        // Both should arrive at the same shared secret
        assert_eq!(alice_shared, bob_shared);
        assert_eq!(alice_shared.len(), 32);
        
        // Can use this shared secret as an AES key
        let message = "Secret message between Alice and Bob".to_string();
        let encrypted = encrypt_text(message.clone(), alice_shared.clone()).unwrap();
        let decrypted = decrypt_text(encrypted, bob_shared).unwrap();
        assert_eq!(message, decrypted);
    }

    #[test]
    fn test_x25519_invalid_key_sizes() {
        let (secret, public) = generate_keypair();
        
        // Test with wrong secret key size
        let short_secret = vec![0u8; 16];
        let result = derive_shared_secret(short_secret, public.clone());
        assert!(result.is_err());
        
        // Test with wrong public key size
        let short_public = vec![0u8; 16];
        let result = derive_shared_secret(secret.clone(), short_public);
        assert!(result.is_err());
    }
}
