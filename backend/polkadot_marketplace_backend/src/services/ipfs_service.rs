use reqwest::{multipart, Client};

use crate::models::response::ApiError;

pub struct IpfsService {
    client: Client,
    base_url: String,
    jwt: Option<String>,
}

impl IpfsService {
    pub fn new(jwt: Option<String>) -> Self {
        Self {
            client: Client::new(),
            base_url: "https://api.pinata.cloud".to_string(),
            jwt,
        }
    }

    /// Upload bytes to Pinata IPFS
    pub async fn upload_bytes(&self, data: Vec<u8>) -> Result<String, ApiError> {
        let form = multipart::Form::new()
            .part("file", multipart::Part::bytes(data).file_name("upload.jpg"));

        let mut request = self.client
            .post(&format!("{}/pinning/pinFileToIPFS", self.base_url))
            .multipart(form);

        // Add JWT if available
        if let Some(jwt) = &self.jwt {
            request = request.header("Authorization", format!("Bearer {}", jwt));
        }

        let response = request
            .send()
            .await
            .map_err(|e| ApiError::new(
                axum::http::StatusCode::INTERNAL_SERVER_ERROR,
                format!("Upload failed: {}", e)
            ))?;

        if !response.status().is_success() {
            let status = response.status();
            let error_text = response.text().await.unwrap_or_default();
            
            // Convert reqwest::StatusCode to axum::http::StatusCode
            let axum_status = axum::http::StatusCode::from_u16(status.as_u16())
                .unwrap_or(axum::http::StatusCode::INTERNAL_SERVER_ERROR);
            
            return Err(ApiError::new(axum_status, format!("Pinata failed: {}", error_text)));
        }

        let result: serde_json::Value = response.json().await
            .map_err(|e| ApiError::new(
                axum::http::StatusCode::INTERNAL_SERVER_ERROR,
                format!("Parse failed: {}", e)
            ))?;

        let cid = result["IpfsHash"]
            .as_str()
            .ok_or_else(|| ApiError::new(
                axum::http::StatusCode::INTERNAL_SERVER_ERROR,
                "No CID in response".to_string()
            ))?
            .to_string();

        Ok(cid)
    }

    /// Get IPFS gateway URL for a hash
    pub fn get_gateway_url(&self, hash: &str) -> String {
        format!("https://gateway.pinata.cloud/ipfs/{}", hash)
    }
}