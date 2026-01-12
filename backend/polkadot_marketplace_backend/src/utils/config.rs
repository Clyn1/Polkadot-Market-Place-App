use std::env;

#[derive(Debug, Clone)]
pub struct Config {
    pub server_host: String,
    pub server_port: u16,
    pub pinata_api_key: String,
    pub pinata_secret_key: String,
    // Optional: Use JWT instead
    pub pinata_jwt: Option<String>,
}

impl Config {
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
                .expect("PINATA_API_KEY must be set in .env"),
            pinata_secret_key: env::var("PINATA_SECRET_KEY")
                .expect("PINATA_SECRET_KEY must be set in .env"),
            pinata_jwt: env::var("PINATA_JWT").ok(),
        }
    }

    pub fn server_address(&self) -> String {
        format!("{}:{}", self.server_host, self.server_port)
    }
}