use axum::{
    extract::{Multipart, State},
    http::StatusCode,
    response::IntoResponse,
    Json,
};
use serde_json::json;
use crate::AppState;

pub async fn upload_image(
    State(state): State<AppState>,
    mut multipart: Multipart,
) -> impl IntoResponse {

    let mut file_bytes = None;

    while let Ok(Some(field)) = multipart.next_field().await {
        if field.name() == Some("file") {
            match field.bytes().await {
                Ok(bytes) => {
                    file_bytes = Some(bytes);
                    break;
                }
                Err(e) => {
                    return (
                        StatusCode::BAD_REQUEST,
                        Json(json!({ "error": e.to_string() })),
                    );
                }
            }
        }
    }

    let file = match file_bytes {
        Some(f) => f,
        None => {
            return (
                StatusCode::BAD_REQUEST,
                Json(json!({ "error": "No file field named `file` found" })),
            );
        }
    };

    let cid = match state.ipfs_service.upload_bytes(file).await {
        Ok(cid) => cid,
        Err(e) => {
            return (
                StatusCode::INTERNAL_SERVER_ERROR,
                Json(json!({ "error": e.to_string() })),
            );
        }
    };

    (
        StatusCode::OK,
        Json(json!({
            "cid": cid,
            "gateway_url": format!("https://gateway.pinata.cloud/ipfs/{}", cid)
        })),
    )
}
