//! SyncMist Rust Core
//! 
//! This library provides encryption and CRDT functionality
//! for the SyncMist clipboard sync application.

mod frb_generated; /* AUTO INJECTED BY flutter_rust_bridge. This line may not be accurate, and you can change it according to your needs. */

pub mod crypto;

// Re-export main functions for flutter_rust_bridge
pub use crypto::*;

/// Library initialization (called by Flutter)
pub fn init() {
    // Initialize any global state here
}

#[cfg(test)]
mod tests {
    use super::*;

    #[test]
    fn test_init() {
        init();
    }
}
