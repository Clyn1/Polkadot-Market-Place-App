#![cfg_attr(not(feature = "std"), no_std, no_main)]

#[ink::contract]
mod marketplace {
    use ink::prelude::string::String;
    use ink::prelude::vec::Vec;
    use ink::storage::Mapping;

    /// Product structure - Represents a single product in the marketplace
    #[derive(scale::Decode, scale::Encode, Clone, Debug)]
    #[cfg_attr(
        feature = "std",
        derive(scale_info::TypeInfo, ink::storage::traits::StorageLayout)
    )]
    pub struct Product {
        /// Unique product ID
        pub id: u64,
        /// Product name (max 100 chars)
        pub name: String,
        /// Product description (max 500 chars)
        pub description: String,
        /// Price in native token (e.g., DOT/KSM)
        pub price: Balance,
        /// IPFS hash for product image (e.g., QmXxxx...)
        pub ipfs_hash: String,
        /// Seller's account address
        pub seller: AccountId,
        /// Current owner (seller initially, buyer after purchase)
        pub owner: AccountId,
        /// Whether product is available for sale
        pub is_available: bool,
        /// Timestamp when product was created
        pub created_at: u64,
        /// Timestamp when product was sold (None if not sold)
        pub sold_at: Option<u64>,
    }

    /// Marketplace storage - Main contract state
    #[ink(storage)]
    pub struct Marketplace {
        /// Maps product ID -> Product details
        products: Mapping<u64, Product>,
        /// Auto-incrementing counter for product IDs
        next_product_id: u64,
        /// Maps seller address -> list of their product IDs
        seller_products: Mapping<AccountId, Vec<u64>>,
        /// Platform fee in basis points (250 = 2.5%, 1000 = 10%)
        platform_fee_bps: u16,
        /// Treasury account that receives platform fees
        treasury: AccountId,
        /// Contract owner (can update fees)
        owner: AccountId,
    }

    /// Event: Emitted when a product is listed
    #[ink(event)]
    pub struct ProductListed {
        #[ink(topic)]
        product_id: u64,
        #[ink(topic)]
        seller: AccountId,
        name: String,
        price: Balance,
        ipfs_hash: String,
    }

    /// Event: Emitted when a product is purchased
    #[ink(event)]
    pub struct ProductPurchased {
        #[ink(topic)]
        product_id: u64,
        #[ink(topic)]
        buyer: AccountId,
        #[ink(topic)]
        seller: AccountId,
        price: Balance,
        platform_fee: Balance,
    }

    /// Event: Emitted when a product is updated
    #[ink(event)]
    pub struct ProductUpdated {
        #[ink(topic)]
        product_id: u64,
        new_price: Balance,
        is_available: bool,
    }

    /// Event: Emitted when a product is deleted
    #[ink(event)]
    pub struct ProductDeleted {
        #[ink(topic)]
        product_id: u64,
        #[ink(topic)]
        seller: AccountId,
    }

    /// Error types
    #[derive(Debug, PartialEq, Eq, scale::Encode, scale::Decode)]
    #[cfg_attr(feature = "std", derive(scale_info::TypeInfo))]
    pub enum Error {
        ProductNotFound,
        NotSeller,
        ProductNotAvailable,
        InsufficientPayment,
        TransferFailed,
        NameTooLong,
        DescriptionTooLong,
        InvalidIpfsHash,
        NotAuthorized,
        InvalidFee,
        Overflow,
    }

    /// Result type for contract functions
    pub type Result<T> = core::result::Result<T, Error>;

    impl Marketplace {
        /// Constructor - Initialize marketplace with custom settings
        /// 
        /// # Arguments
        /// * `platform_fee_bps` - Platform fee in basis points (250 = 2.5%)
        /// * `treasury` - Account that receives platform fees
        #[ink(constructor)]
        pub fn new(platform_fee_bps: u16, treasury: AccountId) -> Self {
            Self {
                products: Mapping::default(),
                next_product_id: 1,
                seller_products: Mapping::default(),
                platform_fee_bps,
                treasury,
                owner: Self::env().caller(),
            }
        }

        /// Default constructor - Uses 2.5% platform fee
        #[ink(constructor)]
        pub fn default() -> Self {
            let caller = Self::env().caller();
            Self::new(250, caller)
        }

        /// List a new product for sale
        /// 
        /// # Flow:
        /// 1. Validate inputs (name length, description length, IPFS hash)
        /// 2. Create product with unique ID
        /// 3. Store product in contract storage
        /// 4. Add product ID to seller's list
        /// 5. Emit ProductListed event
        /// 
        /// # Arguments
        /// * `name` - Product name (max 100 chars)
        /// * `description` - Product description (max 500 chars)
        /// * `price` - Price in native token
        /// * `ipfs_hash` - IPFS hash from your Flutter app (e.g., QmXxxx...)
        #[ink(message)]
        pub fn list_product(
            &mut self,
            name: String,
            description: String,
            price: Balance,
            ipfs_hash: String,
        ) -> Result<u64> {
            // Validate inputs
            if name.len() > 100 {
                return Err(Error::NameTooLong);
            }
            if description.len() > 500 {
                return Err(Error::DescriptionTooLong);
            }
            if ipfs_hash.len() < 10 || ipfs_hash.len() > 100 {
                return Err(Error::InvalidIpfsHash);
            }

            let caller = self.env().caller();
            let product_id = self.next_product_id;
            let timestamp = self.env().block_timestamp();

            // Create product
            let product = Product {
                id: product_id,
                name: name.clone(),
                description,
                price,
                ipfs_hash: ipfs_hash.clone(),
                seller: caller,
                owner: caller,
                is_available: true,
                created_at: timestamp,
                sold_at: None,
            };

            // Store product
            self.products.insert(product_id, &product);

            // Add to seller's products list
            let mut seller_prods = self.seller_products.get(caller).unwrap_or_default();
            seller_prods.push(product_id);
            self.seller_products.insert(caller, &seller_prods);

            // Increment next ID (safe from overflow in practice)
            self.next_product_id = self.next_product_id
                .checked_add(1)
                .ok_or(Error::Overflow)?;

            // Emit event
            self.env().emit_event(ProductListed {
                product_id,
                seller: caller,
                name,
                price,
                ipfs_hash,
            });

            Ok(product_id)
        }

        /// Purchase a product
        /// 
        /// # Flow:
        /// 1. Verify product exists and is available
        /// 2. Check payment is sufficient
        /// 3. Calculate platform fee (e.g., 2.5% of price)
        /// 4. Transfer seller_amount to seller
        /// 5. Transfer platform_fee to treasury
        /// 6. Update product ownership and availability
        /// 7. Emit ProductPurchased event
        /// 
        /// # Payment Example:
        /// - Product price: 10 DOT
        /// - Platform fee (2.5%): 0.25 DOT
        /// - Seller receives: 9.75 DOT
        /// - Treasury receives: 0.25 DOT
        #[ink(message, payable)]
        pub fn buy_product(&mut self, product_id: u64) -> Result<()> {
            let caller = self.env().caller();
            let payment = self.env().transferred_value();

            // Get product
            let mut product = self.products.get(product_id).ok_or(Error::ProductNotFound)?;

            // Check if available
            if !product.is_available {
                return Err(Error::ProductNotAvailable);
            }

            // Check payment
            if payment < product.price {
                return Err(Error::InsufficientPayment);
            }

            // Calculate fees (safe arithmetic)
            let platform_fee = product.price
                .checked_mul(self.platform_fee_bps as u128)
                .ok_or(Error::Overflow)?
                .checked_div(10000)
                .ok_or(Error::Overflow)?;
            
            let seller_amount = product.price
                .checked_sub(platform_fee)
                .ok_or(Error::Overflow)?;

            // Transfer to seller
            if self.env().transfer(product.seller, seller_amount).is_err() {
                return Err(Error::TransferFailed);
            }

            // Transfer fee to treasury (only if fee > 0)
            if platform_fee > 0 && self.env().transfer(self.treasury, platform_fee).is_err() {
                return Err(Error::TransferFailed);
            }

            // Update product
            product.owner = caller;
            product.is_available = false;
            product.sold_at = Some(self.env().block_timestamp());
            self.products.insert(product_id, &product);

            // Emit event
            self.env().emit_event(ProductPurchased {
                product_id,
                buyer: caller,
                seller: product.seller,
                price: product.price,
                platform_fee,
            });

            Ok(())
        }

        /// Update product details (seller only)
        /// 
        /// # Arguments
        /// * `product_id` - ID of product to update
        /// * `new_price` - Optional new price
        /// * `new_description` - Optional new description
        /// * `is_available` - Optional availability status
        #[ink(message)]
        pub fn update_product(
            &mut self,
            product_id: u64,
            new_price: Option<Balance>,
            new_description: Option<String>,
            is_available: Option<bool>,
        ) -> Result<()> {
            let caller = self.env().caller();
            let mut product = self.products.get(product_id).ok_or(Error::ProductNotFound)?;

            // Only seller can update
            if product.seller != caller {
                return Err(Error::NotSeller);
            }

            // Update fields
            if let Some(price) = new_price {
                product.price = price;
            }
            if let Some(desc) = new_description {
                if desc.len() > 500 {
                    return Err(Error::DescriptionTooLong);
                }
                product.description = desc;
            }
            if let Some(available) = is_available {
                product.is_available = available;
            }

            self.products.insert(product_id, &product);

            // Emit event
            self.env().emit_event(ProductUpdated {
                product_id,
                new_price: product.price,
                is_available: product.is_available,
            });

            Ok(())
        }

        /// Delete/delist a product (seller only)
        #[ink(message)]
        pub fn delete_product(&mut self, product_id: u64) -> Result<()> {
            let caller = self.env().caller();
            let product = self.products.get(product_id).ok_or(Error::ProductNotFound)?;

            // Only seller can delete
            if product.seller != caller {
                return Err(Error::NotSeller);
            }

            // Remove product
            self.products.remove(product_id);

            // Emit event
            self.env().emit_event(ProductDeleted {
                product_id,
                seller: caller,
            });

            Ok(())
        }

        /// Get product by ID
        #[ink(message)]
        pub fn get_product(&self, product_id: u64) -> Option<Product> {
            self.products.get(product_id)
        }

        /// Get all product IDs for a seller
        #[ink(message)]
        pub fn get_seller_products(&self, seller: AccountId) -> Vec<u64> {
            self.seller_products.get(seller).unwrap_or_default()
        }

        /// Get current platform fee
        #[ink(message)]
        pub fn get_platform_fee(&self) -> u16 {
            self.platform_fee_bps
        }

        /// Get treasury address
        #[ink(message)]
        pub fn get_treasury(&self) -> AccountId {
            self.treasury
        }

        /// Update platform fee (owner only)
        #[ink(message)]
        pub fn set_platform_fee(&mut self, new_fee_bps: u16) -> Result<()> {
            if self.env().caller() != self.owner {
                return Err(Error::NotAuthorized);
            }
            if new_fee_bps > 10000 {
                return Err(Error::InvalidFee);
            }
            self.platform_fee_bps = new_fee_bps;
            Ok(())
        }

        /// Update treasury address (owner only)
        #[ink(message)]
        pub fn set_treasury(&mut self, new_treasury: AccountId) -> Result<()> {
            if self.env().caller() != self.owner {
                return Err(Error::NotAuthorized);
            }
            self.treasury = new_treasury;
            Ok(())
        }
    }

    /// Unit tests
    #[cfg(test)]
    mod tests {
        use super::*;

        #[ink::test]
        fn new_works() {
            let accounts = ink::env::test::default_accounts::<ink::env::DefaultEnvironment>();
            let marketplace = Marketplace::new(250, accounts.alice);
            assert_eq!(marketplace.get_platform_fee(), 250);
            assert_eq!(marketplace.get_treasury(), accounts.alice);
        }

        #[ink::test]
        fn list_product_works() {
            let mut marketplace = Marketplace::default();

            let result = marketplace.list_product(
                String::from("Test Product"),
                String::from("Description"),
                1000,
                String::from("QmTestHash123"),
            );

            assert!(result.is_ok());
            let product_id = result.unwrap();
            assert_eq!(product_id, 1);

            let product = marketplace.get_product(product_id).unwrap();
            assert_eq!(product.name, "Test Product");
            assert_eq!(product.price, 1000);
        }

        #[ink::test]
        fn buy_product_works() {
            let accounts = ink::env::test::default_accounts::<ink::env::DefaultEnvironment>();
            let mut marketplace = Marketplace::new(250, accounts.alice);

            // List product as Alice
            let product_id = marketplace
                .list_product(
                    String::from("Product"),
                    String::from("Desc"),
                    1000,
                    String::from("QmHash"),
                )
                .unwrap();

            // Buy as Bob
            ink::env::test::set_caller::<ink::env::DefaultEnvironment>(accounts.bob);
            ink::env::test::set_value_transferred::<ink::env::DefaultEnvironment>(1000);

            let result = marketplace.buy_product(product_id);
            assert!(result.is_ok());

            let product = marketplace.get_product(product_id).unwrap();
            assert_eq!(product.owner, accounts.bob);
            assert!(!product.is_available);
        }
    }
}
