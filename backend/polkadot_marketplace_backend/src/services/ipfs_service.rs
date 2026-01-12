use reqwest::Client;    
use anyhow::{Result, anyhow};

#[derive(Clone)]
pub struct IpfsService {
    client: Client,
    pinata_api_key: String,
    pinata_secret_key: String,
    pinata_jwt: String,
}

impl IpfsService {
    pub fn new(
        pinata_api_key: String,
        pinata_secret_key: String,
        pinata_jwt: String,
    ) -> Self {
        Self {
            client: Client::new(),
            pinata_api_key,
            pinata_secret_key,
            pinata_jwt,
        }
    }

    /// Upload raw bytes to Pinata IPFS
    pub async fn upload_bytes(&self, data: bytes::Bytes) -> Result<String> {
        let url = "https://api.pinata.cloud/pinning/pinFileToIPFS";

        let part = reqwest::multipart::Part::bytes(data.to_vec())
            .file_name("upload");

        let form = reqwest::multipart::Form::new()
            .part("file", part);

        let response = self
            .client
            .post(url)
            // 🔐 Prefer JWT auth
            .bearer_auth(&self.pinata_jwt)
            // If you want API key auth instead, uncomment:
            // .header("pinata_api_key", &self.pinata_api_key)
            // .header("pinata_secret_api_key", &self.pinata_secret_key)
            .multipart(form)
            .send()
            .await?;

        if !response.status().is_success() {
            let text = response.text().await.unwrap_or_default();
            return Err(anyhow!("Pinata upload failed: {}", text));
        }

        let json: serde_json::Value = response.json().await?;
        let cid = json["IpfsHash"]
            .as_str()
            .ok_or_else(|| anyhow!("Missing IpfsHash in Pinata response"))?;

        Ok(cid.to_string())
    }
}
