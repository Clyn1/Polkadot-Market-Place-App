use std::env;

/// Application configuration loaded from environment variables
#[derive(Debug, Clone)]
pub struct Config {
    pub server_host: String,
    pub server_port: u16,
    pub pinata_api_key: String,
    pub pinata_secret_key: String,
}

impl Config {
    /// Load configuration from environment variables
    /// Panics if required variables are missing
    pub fn from_env() -> Self {
        dotenv::dotenv().ok();

        Self {
            server_host: env::var("SERVER_HOST")
                .unwrap_or_else(|_| "127.0.0.1".to_string()),
            server_port: env::var("SERVER_PORT")
                .unwrap_or_else(|_| "8080".to_string())
                .parse()
                .expect("SERVER_PORT must be a valid u16"),
            pinata_api_key: env::var("PINATA_API_KEY")
                .unwrap_or_else(|_| "your_api_key".to_string()),
            pinata_secret_key: env::var("PINATA_SECRET_KEY")
                .unwrap_or_else(|_| "your_secret_key".to_string()),
        }
    }

    /// Get server address as string
    pub fn server_address(&self) -> String {
        format!("{}:{}", self.server_host, self.server_port)
    }
}