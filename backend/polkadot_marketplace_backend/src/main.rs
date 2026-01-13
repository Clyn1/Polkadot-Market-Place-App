mod models;
mod routes;
mod services;
mod utils;

use axum::{
    routing::{delete, get, post, put},
    Router,
};
use std::sync::Arc;
use tower_http::cors::{Any, CorsLayer};
use tower_http::trace::TraceLayer;
use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt};

use crate::routes::{health, products, upload};
use crate::services::{IpfsService, ProductService};
use crate::utils::config::Config;

// ── Application State ───────────────────────────────────────────────
#[derive(Clone)]
pub struct AppState {
    pub product_service: Arc<ProductService>,
    pub ipfs_service: Arc<IpfsService>,
}

#[tokio::main]
async fn main() {
    // ── Logging / tracing ────────────────────────────────────────────
    tracing_subscriber::registry()
        .with(
            tracing_subscriber::EnvFilter::try_from_default_env()
                .unwrap_or_else(|_| {
                    "polkadot_marketplace_backend=debug,tower_http=debug".into()
                }),
        )
        .with(tracing_subscriber::fmt::layer())
        .init();

    // ── Load configuration ───────────────────────────────────────────
    let config = Config::from_env();
    tracing::info!("Configuration loaded");
    tracing::info!("Server will run on {}", config.server_address());

    // ── Initialize services ──────────────────────────────────────────
    let product_service = Arc::new(ProductService::new());
    tracing::info!("Product service initialized");

    // Use JWT from config (it's already Option<String>)
    let ipfs_service = Arc::new(IpfsService::new(config.pinata_jwt.clone()));
    
    if config.pinata_jwt.is_some() {
        tracing::info!("IPFS service initialized (using JWT authentication)");
    } else {
        tracing::warn!("IPFS service initialized WITHOUT JWT - uploads may fail");
    }

    // ── Shared application state ─────────────────────────────────────
    let app_state = AppState {
        product_service,
        ipfs_service,
    };

    // ── CORS (dev-friendly) ──────────────────────────────────────────
    let cors = CorsLayer::new()
        .allow_origin(Any)
        .allow_methods(Any)
        .allow_headers(Any);

    // ── Router ───────────────────────────────────────────────────────
    let app = Router::new()
        // Health
        .route("/health", get(health::health_check))

        // Products
        .route("/api/products", get(products::get_products))
        .route("/api/products", post(products::create_product))
        .route("/api/products/search", get(products::search_products))
        .route("/api/products/:id", get(products::get_product))
        .route("/api/products/:id", put(products::update_product))
        .route("/api/products/:id", delete(products::delete_product))

        // Upload (IPFS)
        .route("/api/upload", post(upload::upload_image))

        // Shared state (ONLY once)
        .with_state(app_state)

        // Middleware
        .layer(cors)
        .layer(TraceLayer::new_for_http());

    // ── Start server ─────────────────────────────────────────────────
    let listener = tokio::net::TcpListener::bind(&config.server_address())
        .await
        .expect("Failed to bind address");

    tracing::info!("🚀 Server running on {}", config.server_address());

    axum::serve(listener, app)
        .await
        .expect("Server crashed");
}