use std::env;

/// Application configuration loaded from environment variables
#[derive(Debug, Clone)]
pub struct Config {
    pub host: String,
    pub port: u16,
    pub pinata_jwt: Option<String>,
}

impl Config {
    /// Load configuration from environment variables
    pub fn from_env() -> Self {
        // Load .env file if it exists
        dotenv::dotenv().ok();

        let host = env::var("HOST").unwrap_or_else(|_| "127.0.0.1".to_string());
        let port = env::var("PORT")
            .unwrap_or_else(|_| "8080".to_string())
            .parse::<u16>()
            .expect("PORT must be a valid u16");

        let pinata_jwt = env::var("PINATA_JWT").ok();

        Self {
            host,
            port,
            pinata_jwt,
        }
    }

    /// Get the full server address (host:port)
    pub fn server_address(&self) -> String {
        format!("{}:{}", self.host, self.port)
    }
}