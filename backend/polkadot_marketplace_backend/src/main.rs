mod models;
mod routes;
mod services;
mod utils;

use axum::{
    routing::{delete, get, post, put},
    Router,
};
use tower_http::cors::{Any, CorsLayer};
use tower_http::trace::TraceLayer;
use tracing_subscriber::{layer::SubscriberExt, util::SubscriberInitExt};

use crate::routes::{health, products};
use crate::services::ProductService;
use crate::utils::config::Config;

#[tokio::main]
async fn main() {
    // Initialize tracing/logging
    tracing_subscriber::registry()
        .with(
            tracing_subscriber::EnvFilter::try_from_default_env()
                .unwrap_or_else(|_| "polkadot_marketplace_backend=debug,tower_http=debug".into()),
        )
        .with(tracing_subscriber::fmt::layer())
        .init();

    // Load configuration
    let config = Config::from_env();
    tracing::info!("Configuration loaded");
    tracing::info!("Server will run on: {}", config.server_address());

    // Initialize services
    let product_service = ProductService::new();
    tracing::info!("Product service initialized");

    // Configure CORS (allow Flutter frontend)
    let cors = CorsLayer::new()
        .allow_origin(Any)
        .allow_methods(Any)
        .allow_headers(Any);

    // Build application router
    let app = Router::new()
        // Health check
        .route("/health", get(health::health_check))
        // Product routes
        .route("/api/products", get(products::get_products))
        .route("/api/products", post(products::create_product))
        .route("/api/products/search", get(products::search_products))
        .route("/api/products/:id", get(products::get_product))
        .route("/api/products/:id", put(products::update_product))
        .route("/api/products/:id", delete(products::delete_product))
        // Add shared state
        .with_state(product_service)
        // Add middleware
        .layer(cors)
        .layer(TraceLayer::new_for_http());

    // Start server
    let listener = tokio::net::TcpListener::bind(&config.server_address())
        .await
        .expect("Failed to bind to address");

    tracing::info!("🚀 Server started on {}", config.server_address());
    tracing::info!("📝 API documentation:");
    tracing::info!("  GET    /health");
    tracing::info!("  GET    /api/products");
    tracing::info!("  GET    /api/products/:id");
    tracing::info!("  POST   /api/products");
    tracing::info!("  PUT    /api/products/:id");
    tracing::info!("  DELETE /api/products/:id");
    tracing::info!("  GET    /api/products/search?q=query");

    axum::serve(listener, app)
        .await
        .expect("Failed to start server");
}