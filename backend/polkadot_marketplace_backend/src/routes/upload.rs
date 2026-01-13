use axum::{
    extract::{Multipart, State},
    http::StatusCode,
    response::Json,
};
use serde_json::{json, Value};

use crate::AppState;

/// Upload image to IPFS via Pinata
/// 
/// This endpoint accepts multipart/form-data with a 'file' field
/// Maximum file size: 50MB
pub async fn upload_image(
    State(state): State<AppState>,
    mut multipart: Multipart,
) -> Result<Json<Value>, (StatusCode, Json<Value>)> {
    tracing::info!("📤 Received upload request");

    // Extract file from multipart
    let mut file_data: Option<Vec<u8>> = None;
    let mut field_count = 0;

    // Process each field in the multipart form
    loop {
        match multipart.next_field().await {
            Ok(Some(field)) => {
                field_count += 1;
                let name = field.name().unwrap_or("").to_string();
                let filename = field.file_name().map(|s| s.to_string());
                let content_type = field.content_type().map(|s| s.to_string());
                
                tracing::info!(
                    "Field #{}: name='{}', filename={:?}, content_type={:?}", 
                    field_count, name, filename, content_type
                );

                if name == "file" {
                    // Read the file bytes
                    match field.bytes().await {
                        Ok(bytes) => {
                            tracing::info!("📦 File received: {} bytes", bytes.len());
                            file_data = Some(bytes.to_vec());
                        }
                        Err(e) => {
                            tracing::error!("Failed to read file bytes: {}", e);
                            return Err((
                                StatusCode::BAD_REQUEST,
                                Json(json!({ 
                                    "success": false,
                                    "error": format!("Failed to read file: {}", e) 
                                })),
                            ));
                        }
                    }
                }
            }
            Ok(None) => {
                // No more fields
                tracing::info!("All fields processed. Total: {}", field_count);
                break;
            }
            Err(e) => {
                tracing::error!("Multipart parsing error: {}", e);
                return Err((
                    StatusCode::BAD_REQUEST,
                    Json(json!({ 
                        "success": false,
                        "error": format!("Multipart error: {}", e) 
                    })),
                ));
            }
        }
    }

    // Validate that we received a file
    let file = file_data.ok_or_else(|| {
        tracing::error!("No file found in request");
        (
            StatusCode::BAD_REQUEST,
            Json(json!({ 
                "success": false,
                "error": "No file provided in 'file' field" 
            })),
        )
    })?;

    tracing::info!("📤 Uploading {} bytes to IPFS...", file.len());

    // Upload to IPFS via Pinata
    let cid = match state.ipfs_service.upload_bytes(file).await {
        Ok(cid) => {
            tracing::info!("✅ Upload successful: {}", cid);
            cid
        }
        Err(e) => {
            tracing::error!("❌ IPFS upload failed: {}", e);
            return Err((
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(json!({ 
                    "success": false,
                    "error": format!("IPFS upload failed: {}", e) 
                })),
            ));
        }
    };

    let gateway_url = state.ipfs_service.get_gateway_url(&cid);

    tracing::info!("🎉 Upload complete. CID: {}", cid);

    Ok(Json(json!({
        "success": true,
        "data": {
            "ipfs_hash": cid,
            "gateway_url": gateway_url
        },
        "message": "File uploaded successfully"
    })))
}