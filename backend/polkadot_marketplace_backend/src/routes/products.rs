use axum::{
    extract::{Path, Query, State},
    http::StatusCode,
    response::IntoResponse,
    Json,
};
use serde::Deserialize;

use crate::models::{ApiResponse, CreateProductRequest, UpdateProductRequest};
use crate::AppState;  // ← IMPORTANT: Import the new AppState

#[derive(Debug, Deserialize)]
pub struct SearchQuery {
    q: String,
}

pub async fn get_products(
    State(state): State<AppState>,   // ← Changed from ProductService to AppState
) -> Result<impl IntoResponse, impl IntoResponse> {
    match state.product_service.get_all_products() {
        Ok(products) => Ok((
            StatusCode::OK,
            Json(ApiResponse::success(products)),
        )),
        Err(err) => Err(err),
    }
}

pub async fn get_product(
    State(state): State<AppState>,
    Path(id): Path<String>,
) -> Result<impl IntoResponse, impl IntoResponse> {
    match state.product_service.get_product_by_id(&id) {
        Ok(product) => Ok((
            StatusCode::OK,
            Json(ApiResponse::success(product)),
        )),
        Err(err) => Err(err),
    }
}

pub async fn create_product(
    State(state): State<AppState>,
    Json(request): Json<CreateProductRequest>,
) -> Result<impl IntoResponse, impl IntoResponse> {
    match state.product_service.create_product(request) {
        Ok(product) => Ok((
            StatusCode::CREATED,
            Json(ApiResponse::success_with_message(
                product,
                "Product created successfully".to_string(),
            )),
        )),
        Err(err) => Err(err),
    }
}

pub async fn update_product(
    State(state): State<AppState>,
    Path(id): Path<String>,
    Json(request): Json<UpdateProductRequest>,
) -> Result<impl IntoResponse, impl IntoResponse> {
    match state.product_service.update_product(&id, request) {
        Ok(product) => Ok((
            StatusCode::OK,
            Json(ApiResponse::success_with_message(
                product,
                "Product updated successfully".to_string(),
            )),
        )),
        Err(err) => Err(err),
    }
}

pub async fn delete_product(
    State(state): State<AppState>,
    Path(id): Path<String>,
) -> Result<impl IntoResponse, impl IntoResponse> {
    match state.product_service.delete_product(&id) {
        Ok(_) => Ok((
            StatusCode::OK,
            Json(ApiResponse::<()>::success_with_message(
                (),
                "Product deleted successfully".to_string(),
            )),
        )),
        Err(err) => Err(err),
    }
}

pub async fn search_products(
    State(state): State<AppState>,
    Query(params): Query<SearchQuery>,
) -> Result<impl IntoResponse, impl IntoResponse> {
    match state.product_service.search_products(&params.q) {
        Ok(products) => Ok((
            StatusCode::OK,
            Json(ApiResponse::success(products)),
        )),
        Err(err) => Err(err),
    }
}
