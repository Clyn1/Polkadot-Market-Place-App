use serde::{Deserialize, Serialize};
use chrono::{DateTime, Utc};
use uuid::Uuid;

/// Product model representing a marketplace item
#[derive(Debug, Clone, Serialize, Deserialize)]
pub struct Product {
    pub id: String,
    pub name: String,
    pub price: f64,
    pub owner: String,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub description: Option<String>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub image_url: Option<String>,
    pub created_at: DateTime<Utc>,
    #[serde(skip_serializing_if = "Option::is_none")]
    pub ipfs_hash: Option<String>,
}

impl Product {
    /// Create a new product
    pub fn new(
        name: String,
        price: f64,
        owner: String,
        description: Option<String>,
        image_url: Option<String>,
    ) -> Self {
        Self {
            id: Uuid::new_v4().to_string(),
            name,
            price,
            owner,
            description,
            image_url,
            created_at: Utc::now(),
            ipfs_hash: None,
        }
    }
}

/// Request body for creating a new product
#[derive(Debug, Deserialize)]
pub struct CreateProductRequest {
    pub name: String,
    pub price: f64,
    pub owner: String,
    pub description: Option<String>,
    pub image_url: Option<String>,
}

/// Request body for updating a product
#[derive(Debug, Deserialize)]
pub struct UpdateProductRequest {
    pub name: Option<String>,
    pub price: Option<f64>,
    pub description: Option<String>,
    pub image_url: Option<String>,
}