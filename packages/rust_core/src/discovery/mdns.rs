use mdns_sd::{ServiceDaemon, ServiceEvent, ServiceInfo};
use std::collections::HashMap;
use std::sync::Arc;
use tokio::sync::mpsc::{channel, Receiver};
use tokio::sync::Mutex;
use std::time::{SystemTime, UNIX_EPOCH};

const SERVICE_TYPE: &str = "_syncmist._udp.local.";
const DEFAULT_PORT: u16 = 9876;

/// mDNS discovery errors
#[derive(Debug)]
#[flutter_rust_bridge::frb]
pub enum DiscoveryError {
    /// Failed to register service
    Registration(String),
    /// Failed to browse for services
    Browse(String),
    /// Failed to parse service info
    Parse(String),
}

impl std::fmt::Display for DiscoveryError {
    fn fmt(&self, f: &mut std::fmt::Formatter<'_>) -> std::fmt::Result {
        match self {
            DiscoveryError::Registration(e) => write!(f, "Registration error: {}", e),
            DiscoveryError::Browse(e) => write!(f, "Browse error: {}", e),
            DiscoveryError::Parse(e) => write!(f, "Parse error: {}", e),
        }
    }
}

impl std::error::Error for DiscoveryError {}

/// Information about a discovered peer
#[flutter_rust_bridge::frb]
#[derive(Clone, Debug)]
pub struct PeerInfo {
    pub device_id: String,
    pub device_name: String,
    pub addresses: Vec<String>,
    pub port: u16,
    pub discovered_at: u64,
}

/// mDNS Discovery service for finding peers on the local network
#[flutter_rust_bridge::frb]
pub struct MdnsDiscovery {
    daemon: ServiceDaemon,
    device_id: String,
    device_name: String,
    discovered_peers: Arc<Mutex<Vec<PeerInfo>>>,
}

impl MdnsDiscovery {
    /// Create a new mDNS discovery instance
    #[flutter_rust_bridge::frb]
    pub fn new(device_id: String, device_name: String) -> Result<Self, DiscoveryError> {
        let daemon = ServiceDaemon::new()
            .map_err(|e| DiscoveryError::Registration(format!("Failed to create daemon: {}", e)))?;
        Ok(Self {
            daemon,
            device_id,
            device_name,
            discovered_peers: Arc::new(Mutex::new(Vec::new())),
        })
    }

    /// Register this device on the network
    #[flutter_rust_bridge::frb]
    pub fn register(&self, port: u16) -> Result<(), DiscoveryError> {
        let mut properties = HashMap::new();
        properties.insert("proto".to_string(), "syncmist".to_string());
        properties.insert("v".to_string(), "2".to_string());
        properties.insert("name".to_string(), self.device_name.clone());
        properties.insert("id".to_string(), self.device_id.clone());

        // For mDNS, we need a hostname-like string for the service instance name
        // Usually <device_name>-<device_id>._syncmist._udp.local.
        let instance_name = format!("{}-{}", self.device_name, &self.device_id[..8]);

        let service_info = ServiceInfo::new(
            SERVICE_TYPE,
            &instance_name,
            &format!("{}.local.", instance_name),
            "", // host_ipv4 (empty for all)
            port,
            Some(properties),
        ).map_err(|e| DiscoveryError::Registration(format!("Failed to create service: {}", e)))?;

        self.daemon.register(service_info)
            .map_err(|e| DiscoveryError::Registration(format!("Failed to register: {}", e)))?;
        
        println!("[mDNS] Registered service: {}", instance_name);
        Ok(())
    }

    /// Start browsing for peers on the network
    /// This starts a background task that populates discovered_peers
    #[flutter_rust_bridge::frb]
    pub fn start_browsing(&self) -> Result<(), DiscoveryError> {
        let receiver = self.daemon.browse(SERVICE_TYPE)
            .map_err(|e| DiscoveryError::Browse(format!("Failed to browse: {}", e)))?;
        
        let my_id = self.device_id.clone();
        let peers = self.discovered_peers.clone();

        println!("[mDNS] Starting browsing for peers...");
        
        tokio::spawn(async move {
            while let Ok(event) = receiver.recv_async().await {
                if let ServiceEvent::ServiceResolved(info) = event {
                    // Extract peer info from TXT records using get_property_val_str
                    let device_id = info.get_property_val_str("id")
                        .map(|s| s.to_string())
                        .unwrap_or_default();
                    let device_name = info.get_property_val_str("name")
                        .map(|s| s.to_string())
                        .unwrap_or_default();

                    // Filter out self
                    if device_id == my_id || device_id.is_empty() {
                        continue;
                    }

                    let addresses: Vec<String> = info.get_addresses()
                        .iter()
                        .map(|ip| ip.to_string())
                        .collect();

                    let now = SystemTime::now()
                        .duration_since(UNIX_EPOCH)
                        .unwrap_or_default()
                        .as_secs();

                    let peer = PeerInfo {
                        device_id: device_id.clone(),
                        device_name,
                        addresses,
                        port: info.get_port(),
                        discovered_at: now,
                    };

                    println!("[mDNS] Discovered peer: {}", device_id);
                    
                    // Add or update peer in the list
                    let mut peers_guard = peers.lock().await;
                    if let Some(existing) = peers_guard.iter_mut().find(|p| p.device_id == peer.device_id) {
                        *existing = peer;
                    } else {
                        peers_guard.push(peer);
                    }
                }
            }
        });

        Ok(())
    }

    /// Get the list of currently discovered peers
    #[flutter_rust_bridge::frb]
    pub async fn get_discovered_peers(&self) -> Vec<PeerInfo> {
        let peers = self.discovered_peers.lock().await;
        peers.clone()
    }

    /// Stop discovery and unregister service
    #[flutter_rust_bridge::frb]
    pub fn stop(&self) -> Result<(), DiscoveryError> {
        println!("[mDNS] Stopping discovery...");
        self.daemon.shutdown()
            .map_err(|e| DiscoveryError::Registration(format!("Failed to shutdown: {}", e)))?;
        Ok(())
    }
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_create_discovery() {
        // Verify MdnsDiscovery::new works
        let device_id = "test-device-123".to_string();
        let device_name = "Test Device".to_string();
        
        let result = MdnsDiscovery::new(device_id.clone(), device_name.clone());
        assert!(result.is_ok(), "MdnsDiscovery::new should succeed");
        
        let discovery = result.unwrap();
        assert_eq!(discovery.device_id, device_id, "Device ID should match");
        assert_eq!(discovery.device_name, device_name, "Device name should match");
    }

    #[test]
    fn test_peer_info_serialization() {
        // Verify PeerInfo can be created and has expected fields
        let peer = PeerInfo {
            device_id: "peer-456".to_string(),
            device_name: "Peer Device".to_string(),
            addresses: vec!["192.168.1.100".to_string(), "192.168.1.101".to_string()],
            port: 9876,
            discovered_at: 1234567890,
        };
        
        assert_eq!(peer.device_id, "peer-456");
        assert_eq!(peer.device_name, "Peer Device");
        assert_eq!(peer.addresses.len(), 2);
        assert_eq!(peer.addresses[0], "192.168.1.100");
        assert_eq!(peer.port, 9876);
        assert_eq!(peer.discovered_at, 1234567890);
        
        // Test cloning
        let peer_clone = peer.clone();
        assert_eq!(peer_clone.device_id, peer.device_id);
        assert_eq!(peer_clone.device_name, peer.device_name);
    }

    #[test]
    fn test_register_service() {
        // Verify service registration works (basic test)
        let device_id = "test-reg-789".to_string();
        let device_name = "Registration Test".to_string();
        
        let discovery = MdnsDiscovery::new(device_id, device_name);
        assert!(discovery.is_ok(), "Should create discovery service");
        
        let discovery = discovery.unwrap();
        
        // Try to register service on a random high port
        // Note: This may fail on some systems due to network restrictions
        let result = discovery.register(19876);
        
        // We expect this to either succeed or fail with a specific error
        // The important thing is that it doesn't panic
        match result {
            Ok(_) => {
                println!("Service registration succeeded");
                // Clean up
                let _ = discovery.stop();
            }
            Err(e) => {
                println!("Service registration failed (expected on some systems): {}", e);
                // This is acceptable - some systems may restrict mDNS
                assert!(e.to_string().contains("Registration error"));
            }
        }
    }

    #[tokio::test]
    async fn test_start_browsing() {
        // Verify browsing can be started
        let device_id = "test-browse-101".to_string();
        let device_name = "Browse Test".to_string();
        
        let discovery = MdnsDiscovery::new(device_id, device_name);
        assert!(discovery.is_ok(), "Should create discovery service");
        
        let discovery = discovery.unwrap();
        
        // Start browsing
        let result = discovery.start_browsing();
        
        // Browsing may fail on some systems, but shouldn't panic
        match result {
            Ok(_) => {
                println!("Browsing started successfully");
                
                // Initially should have no peers
                let peers = discovery.get_discovered_peers().await;
                assert!(peers.is_empty(), "Should have no peers initially");
                
                // Clean up
                let _ = discovery.stop();
            }
            Err(e) => {
                println!("Browsing failed (expected on some systems): {}", e);
                assert!(e.to_string().contains("Browse error"));
            }
        }
    }

    #[tokio::test]
    async fn test_get_discovered_peers_empty() {
        let discovery = MdnsDiscovery::new("test-123".to_string(), "Test".to_string()).unwrap();
        let peers = discovery.get_discovered_peers().await;
        assert!(peers.is_empty(), "Should have no discovered peers initially");
    }

    #[test]
    fn test_discovery_error_display() {
        let err = DiscoveryError::Registration("test error".to_string());
        assert!(err.to_string().contains("Registration error"));
        
        let err = DiscoveryError::Browse("browse error".to_string());
        assert!(err.to_string().contains("Browse error"));
        
        let err = DiscoveryError::Parse("parse error".to_string());
        assert!(err.to_string().contains("Parse error"));
    }

    #[test]
    fn test_service_constants() {
        assert_eq!(SERVICE_TYPE, "_syncmist._udp.local.");
        assert_eq!(DEFAULT_PORT, 9876);
    }

    // Integration test: Register and browse
    #[tokio::test]
    async fn test_register_and_browse_integration() {
        // Create two discovery instances
        let discovery1 = MdnsDiscovery::new("device-1".to_string(), "Device One".to_string());
        let discovery2 = MdnsDiscovery::new("device-2".to_string(), "Device Two".to_string());
        
        if discovery1.is_err() || discovery2.is_err() {
            println!("Cannot create discovery instances - skipping integration test");
            return;
        }
        
        let discovery1 = discovery1.unwrap();
        let discovery2 = discovery2.unwrap();
        
        // Try to register first device
        if let Ok(_) = discovery1.register(29876) {
            // Start browsing on second device
            if let Ok(_) = discovery2.start_browsing() {
                // Wait a bit for discovery
                tokio::time::sleep(std::time::Duration::from_millis(500)).await;
                
                // Check if device 1 was discovered by device 2
                let peers = discovery2.get_discovered_peers().await;
                println!("Discovered {} peers", peers.len());
                
                // Note: This may or may not find peers depending on system/network configuration
                // The important thing is that it doesn't crash
            }
            
            // Clean up
            let _ = discovery1.stop();
            let _ = discovery2.stop();
        } else {
            println!("Could not register service - skipping integration test");
        }
    }
}
