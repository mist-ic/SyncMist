use mdns_sd::{ServiceDaemon, ServiceEvent, ServiceInfo};
use std::collections::HashMap;
use std::sync::Arc;
use tokio::sync::mpsc::{channel, Receiver};
use std::time::{SystemTime, UNIX_EPOCH};

const SERVICE_TYPE: &str = "_syncmist._udp.local.";
const DEFAULT_PORT: u16 = 9876;

#[derive(Debug, thiserror::Error)]
pub enum DiscoveryError {
    #[error("Registration error")]
    Registration,
    #[error("Browse error")]
    Browse,
    #[error("Parse error")]
    Parse,
}

#[flutter_rust_bridge::frb]
#[derive(Clone, Debug)]
pub struct PeerInfo {
    pub device_id: String,
    pub device_name: String,
    pub addresses: Vec<String>,
    pub port: u16,
    pub discovered_at: u64,
}

#[flutter_rust_bridge::frb]
pub struct MdnsDiscovery {
    daemon: ServiceDaemon,
    device_id: String,
    device_name: String,
}

impl MdnsDiscovery {
    pub fn new(device_id: String, device_name: String) -> Result<Self, DiscoveryError> {
        let daemon = ServiceDaemon::new().map_err(|_| DiscoveryError::Registration)?;
        Ok(Self {
            daemon,
            device_id,
            device_name,
        })
    }

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
        ).map_err(|_| DiscoveryError::Registration)?;

        self.daemon.register(service_info).map_err(|_| DiscoveryError::Registration)?;
        Ok(())
    }

    pub fn start_browsing(&self) -> Result<Receiver<PeerInfo>, DiscoveryError> {
        let receiver = self.daemon.browse(SERVICE_TYPE).map_err(|_| DiscoveryError::Browse)?;
        let (tx, rx) = channel(100);
        let my_id = self.device_id.clone();

        tokio::spawn(async move {
            while let Ok(event) = receiver.recv_async().await {
                if let ServiceEvent::ServiceResolved(info) = event {
                    // Extract peer info from TXT records
                    let properties = info.get_properties();
                    let device_id = properties.get("id").cloned().unwrap_or_default();
                    let device_name = properties.get("name").cloned().unwrap_or_default();

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
                        device_id,
                        device_name,
                        addresses,
                        port: info.get_port(),
                        discovered_at: now,
                    };

                    let _ = tx.send(peer).await;
                }
            }
        });

        Ok(rx)
    }

    pub fn stop(&self) -> Result<(), DiscoveryError> {
        self.daemon.shutdown().map_err(|_| DiscoveryError::Registration)?;
        Ok(())
    }
}
