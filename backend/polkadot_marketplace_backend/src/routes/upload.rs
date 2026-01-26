use actix_web::{post, web, HttpResponse};
use serde::{Deserialize, Serialize};
use std::env;

#[derive(Deserialize)]
pub struct UploadImageRequest {
    pub image_base64: String,
    pub file_name: String,
}

#[derive(Serialize)]
pub struct UploadImageResponse {
    pub success: bool,
    pub ipfs_hash: String,
    pub gateway_url: String,
}

#[derive(Serialize)]
pub struct ErrorResponse {
    pub success: bool,
    pub error: String,
}

#[post("/upload/image")]
pub async fn upload_image(req: web::Json<UploadImageRequest>) -> HttpResponse {
    log::info!("📥 Received upload request for: {}", req.file_name);

    // Decode base64
    let image_bytes = match base64::decode(&req.image_base64) {
        Ok(bytes) => bytes,
        Err(e) => {
            log::error!("Base64 decode error: {}", e);
            return HttpResponse::BadRequest().json(ErrorResponse {
                success: false,
                error: format!("Invalid base64: {}", e),
            });
        }
    };

    log::info!("✅ Decoded {} bytes", image_bytes.len());

    // Upload to Pinata
    match upload_to_pinata(&image_bytes, &req.file_name).await {
        Ok(ipfs_hash) => {
            log::info!("✅ Uploaded to IPFS: {}", ipfs_hash);
            HttpResponse::Ok().json(UploadImageResponse {
                success: true,
                ipfs_hash: ipfs_hash.clone(),
                gateway_url: format!("https://gateway.pinata.cloud/ipfs/{}", ipfs_hash),
            })
        }
        Err(e) => {
            log::error!("Upload failed: {}", e);
            HttpResponse::InternalServerError().json(ErrorResponse {
                success: false,
                error: format!("Upload failed: {}", e),
            })
        }
    }
}

async fn upload_to_pinata(
    file_data: &[u8],
    file_name: &str,
) -> Result<String, Box<dyn std::error::Error>> {
    let api_key = env::var("PINATA_API_KEY").unwrap_or_default();
    let secret_key = env::var("PINATA_SECRET_KEY").unwrap_or_default();

    // If no keys, return mock hash for testing
    if api_key.is_empty() || secret_key.is_empty() {
        log::warn!("⚠️ No Pinata keys, returning mock hash");
        let mock_hash = format!("QmMock{}", uuid::Uuid::new_v4().simple());
        return Ok(mock_hash);
    }

    log::info!("🔑 Using Pinata API keys");

    let client = reqwest::Client::new();
    let part = reqwest::multipart::Part::bytes(file_data.to_vec())
        .file_name(file_name.to_string())
        .mime_str("image/jpeg")?;

    let form = reqwest::multipart::Form::new().part("file", part);

    let response = client
        .post("https://api.pinata.cloud/pinning/pinFileToIPFS")
        .header("pinata_api_key", &api_key)
        .header("pinata_secret_api_key", &secret_key)
        .multipart(form)
        .send()
        .await?;

    if !response.status().is_success() {
        let status = response.status();
        let body = response.text().await?;
        log::error!("Pinata error {}: {}", status, body);
        return Err(format!("Pinata API error: {}", status).into());
    }

    let json: serde_json::Value = response.json().await?;
    let ipfs_hash = json["IpfsHash"]
        .as_str()
        .ok_or("No IpfsHash in response")?
        .to_string();

    Ok(ipfs_hash)
}
