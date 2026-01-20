#![cfg_attr(not(feature = "std"), no_std, no_main)]

#[ink::contract]
mod marketplace {
    use ink::prelude::string::String;
    use ink::prelude::vec::Vec;
    use ink::storage::Mapping;

    /// Product data structure
    #[derive(scale::Decode, scale::Encode, Clone, Debug)]
    #[cfg_attr(
        feature = "std",
        derive(scale_info::TypeInfo, ink::storage::traits::StorageLayout)
    )]
    pub struct Product {
        pub id: u64,
        pub name: String,
        pub description: String,
        pub price: Balance,
        pub ipfs_hash: String,
        pub seller: AccountId,
        pub owner: AccountId,
        pub is_available: bool,
        pub created_at: u64,
        pub sold_at: Option<u64>,
    }

    /// Marketplace contract storage
    #[ink(storage)]
    pub struct Marketplace {
        products: Mapping<u64, Product>,
        next_product_id: u64,
        seller_products: Mapping<AccountId, Vec<u64>>,
        platform_fee_bps: u16,
        treasury: AccountId,
        owner: AccountId,
    }

    /// Events
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

    #[ink(event)]
    pub struct ProductUpdated {
        #[ink(topic)]
        product_id: u64,
        new_price: Balance,
        is_available: bool,
    }

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

    pub type Result<T> = core::result::Result<T, Error>;

    impl Marketplace {
        /// Constructor
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

        /// Default constructor with 2.5% fee
        #[ink(constructor)]
        pub fn default() -> Self {
            let caller = Self::env().caller();
            Self::new(250, caller)
        }

        /// List a new product
        #[ink(message)]
        pub fn list_product(
            &mut self,
            name: String,
            description: String,
            price: Balance,
            ipfs_hash: String,
        ) -> Result<u64> {
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

            self.products.insert(product_id, &product);

            let mut seller_prods = self.seller_products.get(caller).unwrap_or_default();
            seller_prods.push(product_id);
            self.seller_products.insert(caller, &seller_prods);

            self.next_product_id = self
                .next_product_id
                .checked_add(1)
                .ok_or(Error::Overflow)?;

            self.env().emit_event(ProductListed {
                product_id,
                seller: caller,
                name,
                price,
                ipfs_hash,
            });

            Ok(product_id)
        }

        /// Buy a product
        #[ink(message, payable)]
        pub fn buy_product(&mut self, product_id: u64) -> Result<()> {
            let caller = self.env().caller();
            let payment = self.env().transferred_value();

            let mut product = self.products.get(product_id).ok_or(Error::ProductNotFound)?;

            if !product.is_available {
                return Err(Error::ProductNotAvailable);
            }

            if payment < product.price {
                return Err(Error::InsufficientPayment);
            }

            let platform_fee = product
                .price
                .checked_mul(self.platform_fee_bps as u128)
                .ok_or(Error::Overflow)?
                .checked_div(10000)
                .ok_or(Error::Overflow)?;

            let seller_amount = product
                .price
                .checked_sub(platform_fee)
                .ok_or(Error::Overflow)?;

            if self.env().transfer(product.seller, seller_amount).is_err() {
                return Err(Error::TransferFailed);
            }

            if platform_fee > 0 && self.env().transfer(self.treasury, platform_fee).is_err() {
                return Err(Error::TransferFailed);
            }

            product.owner = caller;
            product.is_available = false;
            product.sold_at = Some(self.env().block_timestamp());
            self.products.insert(product_id, &product);

            self.env().emit_event(ProductPurchased {
                product_id,
                buyer: caller,
                seller: product.seller,
                price: product.price,
                platform_fee,
            });

            Ok(())
        }

        /// Update product
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

            if product.seller != caller {
                return Err(Error::NotSeller);
            }

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

            self.env().emit_event(ProductUpdated {
                product_id,
                new_price: product.price,
                is_available: product.is_available,
            });

            Ok(())
        }

        /// Delete product
        #[ink(message)]
        pub fn delete_product(&mut self, product_id: u64) -> Result<()> {
            let caller = self.env().caller();
            let product = self.products.get(product_id).ok_or(Error::ProductNotFound)?;

            if product.seller != caller {
                return Err(Error::NotSeller);
            }

            self.products.remove(product_id);

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

        /// Get seller's products
        #[ink(message)]
        pub fn get_seller_products(&self, seller: AccountId) -> Vec<u64> {
            self.seller_products.get(seller).unwrap_or_default()
        }

        /// Get platform fee
        #[ink(message)]
        pub fn get_platform_fee(&self) -> u16 {
            self.platform_fee_bps
        }

        /// Get treasury
        #[ink(message)]
        pub fn get_treasury(&self) -> AccountId {
            self.treasury
        }

        /// Set platform fee (owner only)
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

        /// Set treasury (owner only)
        #[ink(message)]
        pub fn set_treasury(&mut self, new_treasury: AccountId) -> Result<()> {
            if self.env().caller() != self.owner {
                return Err(Error::NotAuthorized);
            }
            self.treasury = new_treasury;
            Ok(())
        }
    }

    #[cfg(test)]
    mod tests {
        use super::*;

        #[ink::test]
        fn new_works() {
            let accounts = ink::env::test::default_accounts::<ink::env::DefaultEnvironment>();
            let marketplace = Marketplace::new(250, accounts.alice);
            assert_eq!(marketplace.get_platform_fee(), 250);
        }

        #[ink::test]
        fn list_product_works() {
            let mut marketplace = Marketplace::default();
            let result = marketplace.list_product(
                String::from("Test"),
                String::from("Description"),
                1000,
                String::from("QmTestHash123"),
            );
            assert!(result.is_ok());
        }
    }
}
