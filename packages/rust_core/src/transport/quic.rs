//! QUIC Transport Implementation for SyncMist
//!
//! Provides secure P2P communication using QUIC protocol with self-signed certificates
//! and Trust On First Use (TOFU) verification.

use std::collections::HashMap;
use std::net::SocketAddr;
use std::sync::Arc;

use futures::Stream;
use quinn::{Connection, Endpoint, ServerConfig, ClientConfig, TransportConfig};
use rustls::pki_types::{CertificateDer, PrivateKeyDer, PrivatePkcs8KeyDer};
use tokio::sync::Mutex;

/// Transport layer errors
#[derive(Debug)]
#[flutter_rust_bridge::frb]
pub enum TransportError {
    /// Connection error
    Connection(String),
    /// IO error
    Io(String),
    /// TLS error
    Tls(String),
    /// Not connected to any endpoint
    NotConnected,
    /// Peer not found in connections
    PeerNotFound(String),
}

impl std::fmt::Display for TransportError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            TransportError::Connection(e) => write!(f, "Connection error: {}", e),
            TransportError::Io(e) => write!(f, "IO error: {}", e),
            TransportError::Tls(e) => write!(f, "TLS error: {}", e),
            TransportError::NotConnected => write!(f, "Not connected"),
            TransportError::PeerNotFound(id) => write!(f, "Peer not found: {}", id),
        }
    }
}

impl std::error::Error for TransportError {}

/// Generate a self-signed certificate for QUIC transport
///
/// Returns a tuple of (certificate, private_key) for use with the QUIC endpoint.
#[flutter_rust_bridge::frb]
pub fn generate_self_signed_cert() -> Result<(Vec<u8>, Vec<u8>), TransportError> {
    println!("[QUIC] Generating self-signed certificate for 'syncmist'");
    
    let cert = rcgen::generate_simple_self_signed(vec!["syncmist".to_string()])
        .map_err(|e| TransportError::Tls(format!("Certificate generation failed: {}", e)))?;
    
    let cert_der = cert.cert.der().to_vec();
    let key_der = cert.key_pair.serialize_der();
    
    println!("[QUIC] Certificate generated successfully");
    Ok((cert_der, key_der))
}

/// Internal function to get certificate types for quinn
fn get_cert_and_key() -> Result<(CertificateDer<'static>, PrivateKeyDer<'static>), TransportError> {
    let (cert_der, key_der) = generate_self_signed_cert()?;
    let cert = CertificateDer::from(cert_der);
    let key = PrivateKeyDer::from(PrivatePkcs8KeyDer::from(key_der));
    Ok((cert, key))
}

/// TOFU (Trust On First Use) Certificate Verifier
///
/// This verifier skips standard certificate verification for P2P connections.
/// TODO: Add fingerprint pinning from pairing for enhanced security.
#[derive(Debug)]
struct TofuCertVerifier;

impl rustls::client::danger::ServerCertVerifier for TofuCertVerifier {
    fn verify_server_cert(
        &self,
        _end_entity: &CertificateDer<'_>,
        _intermediates: &[CertificateDer<'_>],
        _server_name: &rustls::pki_types::ServerName<'_>,
        _ocsp_response: &[u8],
        _now: rustls::pki_types::UnixTime,
    ) -> Result<rustls::client::danger::ServerCertVerified, rustls::Error> {
        // TOFU: Skip standard verification for P2P
        // TODO: Add fingerprint pinning from pairing
        println!("[QUIC] TOFU: Accepting certificate (fingerprint pinning TODO)");
        Ok(rustls::client::danger::ServerCertVerified::assertion())
    }

    fn verify_tls12_signature(
        &self,
        _message: &[u8],
        _cert: &CertificateDer<'_>,
        _dss: &rustls::DigitallySignedStruct,
    ) -> Result<rustls::client::danger::HandshakeSignatureValid, rustls::Error> {
        Ok(rustls::client::danger::HandshakeSignatureValid::assertion())
    }

    fn verify_tls13_signature(
        &self,
        _message: &[u8],
        _cert: &CertificateDer<'_>,
        _dss: &rustls::DigitallySignedStruct,
    ) -> Result<rustls::client::danger::HandshakeSignatureValid, rustls::Error> {
        Ok(rustls::client::danger::HandshakeSignatureValid::assertion())
    }

    fn supported_verify_schemes(&self) -> Vec<rustls::SignatureScheme> {
        vec![
            rustls::SignatureScheme::RSA_PKCS1_SHA256,
            rustls::SignatureScheme::RSA_PKCS1_SHA384,
            rustls::SignatureScheme::RSA_PKCS1_SHA512,
            rustls::SignatureScheme::ECDSA_NISTP256_SHA256,
            rustls::SignatureScheme::ECDSA_NISTP384_SHA384,
            rustls::SignatureScheme::ECDSA_NISTP521_SHA512,
            rustls::SignatureScheme::RSA_PSS_SHA256,
            rustls::SignatureScheme::RSA_PSS_SHA384,
            rustls::SignatureScheme::RSA_PSS_SHA512,
            rustls::SignatureScheme::ED25519,
        ]
    }
}

/// QUIC Transport for P2P clipboard sync
///
/// Manages QUIC connections for secure, low-latency data transfer between peers.
#[flutter_rust_bridge::frb]
pub struct QuicTransport {
    endpoint: Option<Endpoint>,
    connections: Arc<Mutex<HashMap<String, Connection>>>,
    is_server: bool,
}

impl Default for QuicTransport {
    fn default() -> Self {
        Self::new()
    }
}

impl QuicTransport {
    /// Create a new QUIC transport instance
    #[flutter_rust_bridge::frb]
    pub fn new() -> Self {
        println!("[QUIC] Creating new QuicTransport instance");
        Self {
            endpoint: None,
            connections: Arc::new(Mutex::new(HashMap::new())),
            is_server: false,
        }
    }

    /// Start the QUIC server on the specified port
    ///
    /// # Arguments
    /// * `port` - Port number to listen on
    #[flutter_rust_bridge::frb]
    pub async fn start_server(&mut self, port: u16) -> Result<(), TransportError> {
        println!("[QUIC] Starting server on port {}", port);
        
        let (cert, key) = get_cert_and_key()?;
        
        // Configure server
        let mut server_crypto = rustls::ServerConfig::builder()
            .with_no_client_auth()
            .with_single_cert(vec![cert], key)
            .map_err(|e| TransportError::Tls(format!("Server config error: {}", e)))?;
        
        server_crypto.alpn_protocols = vec![b"syncmist".to_vec()];
        
        let mut server_config = ServerConfig::with_crypto(Arc::new(
            quinn::crypto::rustls::QuicServerConfig::try_from(server_crypto)
                .map_err(|e| TransportError::Tls(format!("QUIC server config error: {}", e)))?
        ));
        
        // Configure transport
        let mut transport = TransportConfig::default();
        transport.max_idle_timeout(Some(
            std::time::Duration::from_secs(60).try_into().unwrap()
        ));
        server_config.transport_config(Arc::new(transport));
        
        let addr: SocketAddr = format!("0.0.0.0:{}", port)
            .parse()
            .map_err(|e| TransportError::Connection(format!("Invalid address: {}", e)))?;
        
        let endpoint = Endpoint::server(server_config, addr)
            .map_err(|e| TransportError::Io(format!("Failed to create server endpoint: {}", e)))?;
        
        self.endpoint = Some(endpoint);
        self.is_server = true;
        
        println!("[QUIC] Server started successfully on port {}", port);
        Ok(())
    }

    /// Accept an incoming connection (server only)
    #[flutter_rust_bridge::frb]
    pub async fn accept_connection(&self) -> Result<String, TransportError> {
        let endpoint = self.endpoint.as_ref().ok_or(TransportError::NotConnected)?;
        
        println!("[QUIC] Waiting for incoming connection...");
        
        let incoming = endpoint.accept().await
            .ok_or_else(|| TransportError::Connection("Endpoint closed".to_string()))?;
        
        let connection = incoming.await
            .map_err(|e| TransportError::Connection(format!("Failed to accept connection: {}", e)))?;
        
        let peer_addr = connection.remote_address().to_string();
        println!("[QUIC] Accepted connection from {}", peer_addr);
        
        // Store connection
        let mut connections = self.connections.lock().await;
        connections.insert(peer_addr.clone(), connection);
        
        Ok(peer_addr)
    }

    /// Connect to a peer (client mode)
    ///
    /// # Arguments
    /// * `addr` - IP address or hostname of the peer
    /// * `port` - Port number of the peer
    #[flutter_rust_bridge::frb]
    pub async fn connect_to_peer(&mut self, addr: &str, port: u16) -> Result<String, TransportError> {
        println!("[QUIC] Connecting to peer {}:{}", addr, port);
        
        let (cert, key) = get_cert_and_key()?;
        
        // Configure client with TOFU verifier
        let mut client_crypto = rustls::ClientConfig::builder()
            .dangerous()
            .with_custom_certificate_verifier(Arc::new(TofuCertVerifier))
            .with_client_auth_cert(vec![cert], key)
            .map_err(|e| TransportError::Tls(format!("Client cert error: {}", e)))?;
        
        client_crypto.alpn_protocols = vec![b"syncmist".to_vec()];
        
        let client_config = ClientConfig::new(Arc::new(
            quinn::crypto::rustls::QuicClientConfig::try_from(client_crypto)
                .map_err(|e| TransportError::Tls(format!("QUIC client config error: {}", e)))?
        ));
        
        // Create client endpoint if not already created
        if self.endpoint.is_none() {
            let bind_addr: SocketAddr = "0.0.0.0:0".parse().unwrap();
            let mut endpoint = Endpoint::client(bind_addr)
                .map_err(|e| TransportError::Io(format!("Failed to create client endpoint: {}", e)))?;
            endpoint.set_default_client_config(client_config);
            self.endpoint = Some(endpoint);
        }
        
        let endpoint = self.endpoint.as_ref().ok_or(TransportError::NotConnected)?;
        
        let server_addr: SocketAddr = format!("{}:{}", addr, port)
            .parse()
            .map_err(|e| TransportError::Connection(format!("Invalid address: {}", e)))?;
        
        let connection = endpoint
            .connect(server_addr, "syncmist")
            .map_err(|e| TransportError::Connection(format!("Connect error: {}", e)))?
            .await
            .map_err(|e| TransportError::Connection(format!("Connection failed: {}", e)))?;
        
        let peer_id = connection.remote_address().to_string();
        println!("[QUIC] Connected to peer {}", peer_id);
        
        // Store connection
        let mut connections = self.connections.lock().await;
        connections.insert(peer_id.clone(), connection);
        
        Ok(peer_id)
    }

    /// Send data to a specific peer
    ///
    /// # Arguments
    /// * `peer_id` - The peer identifier (address:port)
    /// * `data` - Data to send
    #[flutter_rust_bridge::frb]
    pub async fn send_data(&self, peer_id: &str, data: Vec<u8>) -> Result<(), TransportError> {
        println!("[QUIC] Sending {} bytes to peer {}", data.len(), peer_id);
        
        let connections = self.connections.lock().await;
        let connection = connections.get(peer_id)
            .ok_or_else(|| TransportError::PeerNotFound(peer_id.to_string()))?;
        
        let mut send = connection.open_uni().await
            .map_err(|e| TransportError::Connection(format!("Failed to open stream: {}", e)))?;
        
        // Send length prefix (4 bytes, big-endian)
        let len = data.len() as u32;
        send.write_all(&len.to_be_bytes()).await
            .map_err(|e| TransportError::Io(format!("Failed to send length: {}", e)))?;
        
        // Send data
        send.write_all(&data).await
            .map_err(|e| TransportError::Io(format!("Failed to send data: {}", e)))?;
        
        send.finish()
            .map_err(|e| TransportError::Io(format!("Failed to finish stream: {}", e)))?;
        
        println!("[QUIC] Data sent successfully");
        Ok(())
    }

    /// Receive data from peers as an async stream
    ///
    /// Returns a stream of (peer_id, data) tuples
    #[flutter_rust_bridge::frb(ignore)]
    pub fn receive_data(&self) -> impl Stream<Item = (String, Vec<u8>)> + '_ {
        let connections = self.connections.clone();
        
        async_stream::stream! {
            loop {
                let conns = connections.lock().await;
                for (peer_id, connection) in conns.iter() {
                    // Try to accept a unidirectional stream
                    match connection.accept_uni().await {
                        Ok(mut recv) => {
                            // Read length prefix
                            let mut len_buf = [0u8; 4];
                            if let Ok(()) = recv.read_exact(&mut len_buf).await {
                                let len = u32::from_be_bytes(len_buf) as usize;
                                
                                // Read data
                                let mut data = vec![0u8; len];
                                if let Ok(()) = recv.read_exact(&mut data).await {
                                    println!("[QUIC] Received {} bytes from {}", len, peer_id);
                                    yield (peer_id.clone(), data);
                                }
                            }
                        }
                        Err(e) => {
                            println!("[QUIC] No data from {}: {}", peer_id, e);
                        }
                    }
                }
                drop(conns);
                
                // Small delay to prevent busy loop
                tokio::time::sleep(std::time::Duration::from_millis(10)).await;
            }
        }
    }

    /// Disconnect from a peer
    #[flutter_rust_bridge::frb]
    pub async fn disconnect(&self, peer_id: &str) -> Result<(), TransportError> {
        println!("[QUIC] Disconnecting from peer {}", peer_id);
        
        let mut connections = self.connections.lock().await;
        if let Some(connection) = connections.remove(peer_id) {
            connection.close(0u32.into(), b"disconnect");
            println!("[QUIC] Disconnected from {}", peer_id);
            Ok(())
        } else {
            Err(TransportError::PeerNotFound(peer_id.to_string()))
        }
    }

    /// Close the transport and all connections
    #[flutter_rust_bridge::frb]
    pub async fn close(&mut self) {
        println!("[QUIC] Closing transport");
        
        let mut connections = self.connections.lock().await;
        for (peer_id, connection) in connections.drain() {
            connection.close(0u32.into(), b"shutdown");
            println!("[QUIC] Closed connection to {}", peer_id);
        }
        
        if let Some(endpoint) = self.endpoint.take() {
            endpoint.close(0u32.into(), b"shutdown");
        }
        
        println!("[QUIC] Transport closed");
    }

    /// Check if transport is running
    #[flutter_rust_bridge::frb]
    pub fn is_running(&self) -> bool {
        self.endpoint.is_some()
    }

    /// Get list of connected peers
    #[flutter_rust_bridge::frb]
    pub async fn get_connected_peers(&self) -> Vec<String> {
        let connections = self.connections.lock().await;
        connections.keys().cloned().collect()
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_generate_cert() {
        let result = generate_self_signed_cert();
        assert!(result.is_ok());
        let (cert, key) = result.unwrap();
        assert!(!cert.is_empty());
        assert!(!key.is_empty());
    }

    #[test]
    fn test_transport_error_display() {
        let err = TransportError::Connection("test".to_string());
        assert!(err.to_string().contains("Connection error"));
        
        let err = TransportError::NotConnected;
        assert_eq!(err.to_string(), "Not connected");
    }

    #[test]
    fn test_quic_transport_new() {
        let transport = QuicTransport::new();
        assert!(!transport.is_running());
        assert!(!transport.is_server);
    }

    #[tokio::test]
    async fn test_server_start() {
        // Install crypto provider for rustls 0.23+
        let _ = rustls::crypto::ring::default_provider().install_default();
        
        let mut transport = QuicTransport::new();
        let result = transport.start_server(0).await;  // Port 0 = OS assigns port
        assert!(result.is_ok());
        assert!(transport.is_running());
        assert!(transport.is_server);
    }
}
