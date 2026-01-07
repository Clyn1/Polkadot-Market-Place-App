use crate::models::{ApiError, CreateProductRequest, Product, UpdateProductRequest};
use std::collections::HashMap;
use std::sync::{Arc, RwLock};

/// In-memory product store
/// In production, this would be a database (PostgreSQL, MongoDB, etc.)
/// Later: This will query Polkadot blockchain
pub type ProductStore = Arc<RwLock<HashMap<String, Product>>>;

/// Product service handles all product-related business logic
#[derive(Clone)]
pub struct ProductService {
    store: ProductStore,
}

impl ProductService {
    /// Create a new product service
    pub fn new() -> Self {
        Self {
            store: Arc::new(RwLock::new(HashMap::new())),
        }
    }

    /// Get all products
    pub fn get_all_products(&self) -> Result<Vec<Product>, ApiError> {
        let store = self.store.read().map_err(|_| {
            ApiError::internal_server_error("Failed to read product store")
        })?;

        let products: Vec<Product> = store.values().cloned().collect();
        Ok(products)
    }

    /// Get a product by ID
    pub fn get_product_by_id(&self, id: &str) -> Result<Product, ApiError> {
        let store = self.store.read().map_err(|_| {
            ApiError::internal_server_error("Failed to read product store")
        })?;

        store
            .get(id)
            .cloned()
            .ok_or_else(|| ApiError::not_found(format!("Product with id {} not found", id)))
    }

    /// Create a new product
    pub fn create_product(&self, request: CreateProductRequest) -> Result<Product, ApiError> {
        // Validate input
        if request.name.is_empty() {
            return Err(ApiError::bad_request("Product name cannot be empty"));
        }

        if request.price <= 0.0 {
            return Err(ApiError::bad_request("Product price must be greater than 0"));
        }

        if request.owner.is_empty() {
            return Err(ApiError::bad_request("Owner address cannot be empty"));
        }

        // Create product
        let product = Product::new(
            request.name,
            request.price,
            request.owner,
            request.description,
            request.image_url,
        );

        // Store product
        let mut store = self.store.write().map_err(|_| {
            ApiError::internal_server_error("Failed to write to product store")
        })?;

        store.insert(product.id.clone(), product.clone());

        tracing::info!("Created product: {} (ID: {})", product.name, product.id);

        Ok(product)
    }

    /// Update a product
    pub fn update_product(
        &self,
        id: &str,
        request: UpdateProductRequest,
    ) -> Result<Product, ApiError> {
        let mut store = self.store.write().map_err(|_| {
            ApiError::internal_server_error("Failed to write to product store")
        })?;

        let product = store
            .get_mut(id)
            .ok_or_else(|| ApiError::not_found(format!("Product with id {} not found", id)))?;

        // Update fields if provided
        if let Some(name) = request.name {
            if name.is_empty() {
                return Err(ApiError::bad_request("Product name cannot be empty"));
            }
            product.name = name;
        }

        if let Some(price) = request.price {
            if price <= 0.0 {
                return Err(ApiError::bad_request("Product price must be greater than 0"));
            }
            product.price = price;
        }

        if let Some(description) = request.description {
            product.description = Some(description);
        }

        if let Some(image_url) = request.image_url {
            product.image_url = Some(image_url);
        }

        tracing::info!("Updated product: {}", id);

        Ok(product.clone())
    }

    /// Delete a product
    pub fn delete_product(&self, id: &str) -> Result<(), ApiError> {
        let mut store = self.store.write().map_err(|_| {
            ApiError::internal_server_error("Failed to write to product store")
        })?;

        store
            .remove(id)
            .ok_or_else(|| ApiError::not_found(format!("Product with id {} not found", id)))?;

        tracing::info!("Deleted product: {}", id);

        Ok(())
    }

    /// Search products by name
    pub fn search_products(&self, query: &str) -> Result<Vec<Product>, ApiError> {
        let store = self.store.read().map_err(|_| {
            ApiError::internal_server_error("Failed to read product store")
        })?;

        let query_lower = query.to_lowercase();
        let results: Vec<Product> = store
            .values()
            .filter(|p| {
                p.name.to_lowercase().contains(&query_lower)
                    || p.description
                        .as_ref()
                        .map(|d| d.to_lowercase().contains(&query_lower))
                        .unwrap_or(false)
            })
            .cloned()
            .collect();

        Ok(results)
    }
}

impl Default for ProductService {
    fn default() -> Self {
        Self::new()
    }
}