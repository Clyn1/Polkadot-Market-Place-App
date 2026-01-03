#![cfg_attr(not(feature = "std"), no_std)]

#[ink::contract]
mod marketplace {

    use ink::storage::Mapping;

    #[derive(scale::Encode, scale::Decode, Clone, Debug, PartialEq, Eq)]
    #[cfg_attr(feature = "std", derive(scale_info::TypeInfo))]
    pub struct Product {
        id: u32,
        name: Vec<u8>,
        price: Balance,
        seller: AccountId,
        buyer: Option<AccountId>,
        sold: bool,
    }

    #[ink(storage)]
    pub struct Marketplace {
        products: Mapping<u32, Product>,
        product_count: u32,
    }

    impl Marketplace {
        /// Creates a new marketplace
        #[ink(constructor)]
        pub fn new() -> Self {
            Self {
                products: Mapping::default(),
                product_count: 0,
            }
        }

        /// List a product for sale
        #[ink(message)]
        pub fn list_product(&mut self, name: Vec<u8>, price: Balance) -> u32 {
            assert!(price > 0, "Price must be greater than zero");

            let caller = self.env().caller();
            let id = self.product_count;

            let product = Product {
                id,
                name,
                price,
                seller: caller,
                buyer: None,
                sold: false,
            };

            self.products.insert(id, &product);
            self.product_count += 1;

            id
        }

        /// Buy a listed product
        #[ink(message, payable)]
        pub fn buy_product(&mut self, product_id: u32) {
            let mut product = self.products.get(product_id)
                .expect("Product does not exist");

            assert!(!product.sold, "Product already sold");

            let payment = self.env().transferred_value();
            assert!(payment == product.price, "Incorrect payment amount");

            let buyer = self.env().caller();

            self.env()
                .transfer(product.seller, payment)
                .expect("Transfer failed");

            product.buyer = Some(buyer);
            product.sold = true;

            self.products.insert(product_id, &product);
        }

        /// Fetch product details
        #[ink(message)]
        pub fn get_product(&self, product_id: u32) -> Option<Product> {
            self.products.get(product_id)
        }

        /// Get total number of products
        #[ink(message)]
        pub fn get_product_count(&self) -> u32 {
            self.product_count
        }
    }
}
