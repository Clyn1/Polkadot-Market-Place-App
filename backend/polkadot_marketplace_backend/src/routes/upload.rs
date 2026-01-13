use axum::{
    extract::{Multipart, State},
    http::StatusCode,
    response::Json,
};
use serde_json::{json, Value};

use crate::AppState;

/// Upload image to IPFS via Pinata
pub async fn upload_image(
    State(state): State<AppState>,
    mut multipart: Multipart,
) -> Result<Json<Value>, (StatusCode, Json<Value>)> {
    tracing::info!("📤 Received upload request");

    // Extract file from multipart
    let mut file_data: Option<Vec<u8>> = None;

    while let Some(field) = multipart
        .next_field()
        .await
        .map_err(|e| {
            tracing::error!("Failed to read multipart field: {}", e);
            (
                StatusCode::BAD_REQUEST,
                Json(json!({ "error": format!("Multipart error: {}", e) })),
            )
        })?
    {
        let name = field.name().unwrap_or("").to_string();
        tracing::info!("Processing field: {}", name);

        if name == "file" {
            file_data = Some(field.bytes().await.map_err(|e| {
                tracing::error!("Failed to read file bytes: {}", e);
                (
                    StatusCode::BAD_REQUEST,
                    Json(json!({ "error": format!("File read error: {}", e) })),
                )
            })?.to_vec());
        }
    }

    let file = file_data.ok_or_else(|| {
        tracing::error!("No file found in request");
        (
            StatusCode::BAD_REQUEST,
            Json(json!({ "error": "No file provided" })),
        )
    })?;

    tracing::info!("📦 File size: {} bytes", file.len());

    // Upload to IPFS
    let cid = match state.ipfs_service.upload_bytes(file).await {
        Ok(cid) => {
            tracing::info!("✅ Upload successful: {}", cid);
            cid
        }
        Err(e) => {
            tracing::error!("❌ Upload failed: {}", e);
            return Err((
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(json!({ "error": format!("Upload failed: {}", e) })),
            ));
        }
    };

    let gateway_url = state.ipfs_service.get_gateway_url(&cid);

    Ok(Json(json!({
        "success": true,
        "data": {
            "ipfs_hash": cid,
            "gateway_url": gateway_url
        },
        "message": "File uploaded successfully"
    })))
}