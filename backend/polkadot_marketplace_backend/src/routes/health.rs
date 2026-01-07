use axum::{response::IntoResponse, Json};
use serde_json::json;

/// Health check endpoint
/// GET /health
pub async fn health_check() -> impl IntoResponse {
    Json(json!({
        "status": "healthy",
        "service": "polkadot_marketplace_backend",
        "version": env!("CARGO_PKG_VERSION"),
        "timestamp": chrono::Utc::now().to_rfc3339(),
    }))
}