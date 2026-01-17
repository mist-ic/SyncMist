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
