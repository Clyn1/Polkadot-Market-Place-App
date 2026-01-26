use actix_web::{web, App, HttpServer, HttpResponse};
use actix_cors::Cors;

mod routes;

#[actix_web::main]
async fn main() -> std::io::Result<()> {
    dotenv::dotenv().ok();
    env_logger::init_from_env(env_logger::Env::new().default_filter_or("info"));

    log::info!("🚀 Starting Polkadot Marketplace Backend");
    log::info!("📡 Server: http://127.0.0.1:8080");
    
    if std::env::var("PINATA_API_KEY").is_ok() {
        log::info!("✅ Pinata API key found");
    } else {
        log::warn!("⚠️ No Pinata API key - will use mock hashes");
    }

    HttpServer::new(|| {
        let cors = Cors::default()
            .allow_any_origin()
            .allow_any_method()
            .allow_any_header()
            .max_age(3600);

        App::new()
            .wrap(cors)
            .app_data(
                web::JsonConfig::default()
                    .limit(10_485_760)  // ✅ 10MB limit for JSON
            )
            .app_data(
                web::PayloadConfig::default()
                    .limit(10_485_760)  // ✅ 10MB limit for payloads
            )
            .service(
                web::scope("/api")
                    .route("/health", web::get().to(health_check))
                    .service(routes::upload::upload_image),
            )
    })
    .bind("127.0.0.1:8080")?
    .run()
    .await
}

async fn health_check() -> HttpResponse {
    HttpResponse::Ok().json(serde_json::json!({
        "status": "healthy",
        "service": "polkadot-marketplace-backend",
        "version": "1.0.0"
    }))
}