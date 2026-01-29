📋 Table of Contents

Project Description
System Architecture
Rust Backend (Middleware Layer)
IPFS & Pinata Integration
Blockchain & Smart Contracts
API Layer
Security Considerations
Local Development Setup
Hackathon Notes
Future Improvements


🎯 Project Description
What It Does
This decentralized marketplace enables users to:

List products with images and metadata
Purchase products using blockchain-based transactions
Store product images on IPFS for permanent, decentralized access
Record ownership and transactions immutably on the Polkadot blockchain

The Problem It Solves
Traditional e-commerce platforms face critical trust and centralization issues:

Centralized Control: Platforms can arbitrarily remove listings, freeze accounts, or change terms
Data Ownership: Users don't control their data; platforms do
High Fees: Intermediaries extract significant transaction fees
Single Point of Failure: Server outages can halt all operations
Censorship: Platforms can censor content based on location or policy

Why Web3 & Decentralization
Our solution leverages blockchain and decentralized storage to address these issues:

Immutable Ownership Records: Polkadot blockchain ensures tamper-proof transaction history
Decentralized Storage: IPFS guarantees content availability without relying on centralized servers
Trustless Transactions: Smart contracts enable peer-to-peer exchanges without intermediaries
Censorship Resistance: No single entity can remove listings or ban users
Data Sovereignty: Users maintain control over their content and transactions


🏗️ System Architecture
High-Level Overview
┌─────────────────┐
│                 │
│  Flutter App    │  ◄── Cross-platform mobile interface
│  (Frontend)     │      (iOS, Android, Web, Desktop)
│                 │
└────────┬────────┘
         │
         │ REST API (HTTP/JSON)
         │
         ▼
┌─────────────────┐
│                 │
│  Rust Backend   │  ◄── Secure middleware layer
│  (API Server)   │      Handles external integrations
│                 │      Manages secrets & API keys
└────────┬────────┘
         │
         ├──────────────────────┬─────────────────────┐
         │                      │                     │
         ▼                      ▼                     ▼
┌──────────────┐       ┌──────────────┐      ┌──────────────┐
│              │       │              │      │              │
│ Pinata IPFS  │       │  Polkadot    │      │   Smart      │
│   Gateway    │       │  Blockchain  │      │  Contracts   │
│              │       │    Node      │      │   (ink!)     │
└──────────────┘       └──────────────┘      └──────────────┘
     │                        │                      │
     │                        │                      │
     └────────────────────────┴──────────────────────┘
              │
              ▼
        Decentralized
        Infrastructure
Component Interaction Flow

User Action: User uploads product image via Flutter app
API Request: Flutter sends image (base64) to Rust backend via REST API
IPFS Upload: Rust backend uploads image to Pinata (IPFS gateway)
IPFS Hash: Pinata returns content identifier (CID) - e.g., QmXxx...
Blockchain Transaction: Rust backend calls ink! smart contract with product metadata + IPFS hash
On-Chain Storage: Smart contract stores: product ID, owner address, price, IPFS CID
Response: Backend returns success + transaction hash to Flutter
UI Update: Flutter displays product with image loaded from IPFS gateway


🦀 Rust Backend (Middleware Layer)
Why a Backend in Web3?
While Web3 emphasizes decentralization, production systems require a secure middleware layer for several critical reasons:
Security

API Key Management: Pinata API keys must never be exposed in client applications
Transaction Signing: Private keys for blockchain interactions must remain server-side
Rate Limiting: Protects against abuse of external APIs (Pinata, Polkadot RPC)

Abstraction

Simplified Mobile App: Flutter doesn't need blockchain SDK complexity
Consistent API: Backend provides REST endpoints familiar to mobile developers
Error Handling: Centralized error management and retry logic

Performance

Caching: Backend can cache IPFS gateway responses and blockchain queries
Batch Operations: Can group multiple blockchain transactions efficiently
Connection Pooling: Maintains persistent connections to Polkadot node

Architecture Explanation (Judge-Friendly)

The Rust backend acts as secure middleware between the Flutter app, Polkadot blockchain, and IPFS via Pinata.
It handles image uploads to IPFS, manages API keys securely, submits and queries smart contract transactions, and exposes clean REST APIs for the mobile app. This enables a production-style Web3 architecture where sensitive operations and external integrations are handled safely in Rust.
Without this layer, the mobile app would need to:

Embed Pinata API keys (security risk)
Implement complex SCALE codec for contract calls (high complexity)
Manage blockchain transaction signing (key management nightmare)
Handle WebSocket connections to Polkadot node (battery drain on mobile)

By centralizing these concerns in a Rust backend, we achieve enterprise-grade security while keeping the mobile app lightweight and maintainable.

Backend Responsibilities
1. IPFS Integration
rust// Upload image to Pinata
POST /api/upload/image
- Receives base64-encoded image from Flutter
- Uploads to Pinata IPFS gateway
- Returns IPFS CID (content identifier)
2. Blockchain Interaction
rust// Submit contract transaction
- Encodes function calls using SCALE codec
- Signs transactions with backend-managed account
- Submits to Polkadot node via WebSocket
- Polls for transaction finalization
- Returns transaction hash to client
3. API Exposure
rust// RESTful endpoints for Flutter
GET  /api/products         // List all products
POST /api/products         // Create new product
GET  /api/products/:id     // Get product details
POST /api/products/:id/buy // Purchase product
```

#### 4. **Secret Management**
- **Environment Variables**: Loads `.env` file with Pinata JWT, Polkadot seed phrases
- **Never Exposes**: Secrets are never returned in API responses
- **Validation**: Checks for required secrets on startup

### Technology Stack

- **Framework**: Actix-web (high-performance async HTTP server)
- **HTTP Client**: Reqwest (for Pinata API calls)
- **Blockchain**: Polkadot-js alternative (WebSocket connection to node)
- **Serialization**: Serde (JSON parsing)
- **Base64 Handling**: base64 crate (image encoding/decoding)

---

## 🗂️ IPFS & Pinata Integration

### What is IPFS?

**InterPlanetary File System (IPFS)** is a peer-to-peer distributed file system that makes content:
- **Content-Addressed**: Files are identified by cryptographic hash (CID), not location
- **Permanent**: Content cannot be altered without changing its CID
- **Decentralized**: No single server hosts the content
- **Efficient**: Deduplication ensures identical files share the same CID

### What is Pinata?

**Pinata** is an IPFS pinning service that:
- Provides reliable IPFS gateways for content retrieval
- Ensures uploaded content remains available (prevents garbage collection)
- Offers APIs for easy integration
- Handles IPFS infrastructure so we don't need to run our own nodes

### Why IPFS for Images?

Storing images directly on blockchain is impractical because:

| Storage Method | Cost | Speed | Suitability |
|---------------|------|-------|-------------|
| **On-Chain** | $10,000+ per MB | Slow | ❌ Prohibitively expensive |
| **Centralized Server** | $5/month | Fast | ⚠️ Single point of failure |
| **IPFS** | $0.15/GB/month | Fast | ✅ Decentralized & affordable |

### Upload Flow
```
┌─────────┐         ┌──────────┐        ┌─────────┐
│ Flutter │         │   Rust   │        │ Pinata  │
│   App   │         │ Backend  │        │  IPFS   │
└────┬────┘         └────┬─────┘        └────┬────┘
     │                   │                   │
     │ 1. POST /upload   │                   │
     ├──────────────────>│                   │
     │  {image_base64}   │                   │
     │                   │ 2. Upload file    │
     │                   ├──────────────────>│
     │                   │                   │
     │                   │ 3. Return CID     │
     │                   │<──────────────────┤
     │                   │  QmXxx...         │
     │ 4. Return CID     │                   │
     │<──────────────────┤                   │
     │  {ipfs_hash}      │                   │
     │                   │                   │
```

### Retrieval

Images are accessed via Pinata's public gateway:
```
https://gateway.pinata.cloud/ipfs/{CID}
```

For example:
```
https://gateway.pinata.cloud/ipfs/QmUNyjtUTFMq1PjQadUz3VsJfTcXeqUmfx5ySKSgoXEGt7
This URL is:

Permanent: CID never changes if content doesn't change
Verifiable: Anyone can hash the content and verify the CID
Decentralized: Can be accessed through any IPFS gateway, not just Pinata


⛓️ Blockchain & Smart Contracts
Role of Polkadot
Polkadot is a next-generation blockchain that provides:

Interoperability: Parachains can communicate with each other
Scalability: Shared security model across multiple chains
Upgradability: On-chain governance without hard forks
Substrate Framework: Allows custom blockchain development

We use Polkadot for:

Immutable Transaction Records: All product listings and purchases are permanently recorded
Trustless Execution: Smart contracts enforce rules without intermediaries
Transparent History: Anyone can verify ownership and transaction history

Smart Contract (ink!)
ink! is Rust-based smart contract language for Polkadot that compiles to WebAssembly (Wasm).
Contract Responsibilities
rust#[ink::contract]
mod marketplace {
    #[ink(storage)]
    pub struct Marketplace {
        products: Mapping<ProductId, Product>,
        product_count: u64,
    }

    #[ink(message)]
    pub fn list_product(
        &mut self,
        name: String,
        description: String,
        price: Balance,
        ipfs_hash: String,  // ◄── IPFS CID stored here
    ) -> Result<ProductId> {
        // Logic to create product
    }

    #[ink(message)]
    pub fn purchase_product(
        &mut self,
        product_id: ProductId,
    ) -> Result<()> {
        // Logic to transfer ownership
    }
}
On-Chain vs Off-Chain Data
Data TypeStorage LocationReasonProduct IDOn-ChainSmall, critical for indexingProduct NameOn-ChainLightweight textPriceOn-ChainRequired for payment logicOwner AddressOn-ChainRequired for ownership verificationIPFS Hash (CID)On-Chain46 bytes, links to off-chain dataProduct ImageOff-Chain (IPFS)Large binary data (KB-MB)DescriptionOn-ChainOptional metadataTransaction HistoryOn-ChainImmutable audit trail
Backend ↔ Smart Contract Interaction
The Rust backend interacts with the smart contract via:

SCALE Codec Encoding: Converts function calls to byte format

rust   let call_data = encode_call("list_product", (name, description, price, ipfs_hash));

WebSocket RPC: Sends transaction to Polkadot node

rust   let tx_hash = rpc_client.submit_extrinsic(call_data).await?;

Event Listening: Monitors blockchain for transaction finalization

rust   let result = wait_for_block(tx_hash).await?;

Query State: Reads smart contract storage

rust   let products = rpc_client.query_storage("products").await?;

🔌 API Layer
Backend → Frontend Communication
The Rust backend exposes a RESTful JSON API that Flutter consumes.
Endpoints
1. Upload Product Image
httpPOST /api/upload/image
Content-Type: application/json

{
  "image_base64": "iVBORw0KGgoAAAANSUhEUgAA...",
  "file_name": "product.jpg"
}
Response:
json{
  "success": true,
  "ipfs_hash": "QmUNyjtUTFMq1PjQadUz3VsJfTcXeqUmfx5ySKSgoXEGt7",
  "gateway_url": "https://gateway.pinata.cloud/ipfs/QmUNy..."
}
2. List Product
httpPOST /api/products
Content-Type: application/json

{
  "name": "Organic Mangoes",
  "description": "Fresh from Kenya",
  "price": "100000000000",
  "ipfs_hash": "QmUNyjtUTFMq1PjQadUz3VsJfTcXeqUmfx5ySKSgoXEGt7"
}
Response:
json{
  "success": true,
  "product_id": 1,
  "transaction_hash": "0x5c8d...",
  "block_number": 12345
}
3. Get All Products
httpGET /api/products
Response:
json{
  "products": [
    {
      "id": 1,
      "name": "Organic Mangoes",
      "price": "100000000000",
      "ipfs_hash": "QmUNy...",
      "owner": "5GrwvaEF...",
      "is_available": true
    }
  ]
}
4. Purchase Product
httpPOST /api/products/:id/buy
Content-Type: application/json

{
  "buyer_address": "5FHneW46..."
}
Response:
json{
  "success": true,
  "transaction_hash": "0x8a2f...",
  "new_owner": "5FHneW46..."
}
Flutter HTTP Client
Flutter consumes these APIs using the http package:
dart// Upload image
final response = await http.post(
  Uri.parse('http://127.0.0.1:8080/api/upload/image'),
  headers: {'Content-Type': 'application/json'},
  body: json.encode({
    'image_base64': base64Image,
    'file_name': 'product.jpg',
  }),
);

final data = json.decode(response.body);
final ipfsHash = data['ipfs_hash'];

🔒 Security Considerations
Why API Keys Never Touch Flutter
Critical Security Principle: Secrets embedded in mobile apps are not secure.
RiskConsequenceAPK DecompilationAPI keys extracted via reverse engineeringMemory InspectionKeys readable in device RAMNetwork SniffingKeys exposed if app makes direct API callsSource ControlAccidentally committed keys in Git history
Backend-Managed Secrets
The Rust backend stores sensitive data in .env files:
bash# backend/.env
PINATA_JWT=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
POLKADOT_SEED_PHRASE=//Alice
CONTRACT_ADDRESS=5GTwSbGWYsuyMn5Ni8FnPd6Autpt4LKYYuyTcK95FRNvFSYJ
```

These secrets:
- ✅ Never appear in API responses
- ✅ Never sent to client
- ✅ Only accessible to backend process
- ✅ Excluded from version control (`.gitignore`)

### Transaction Signing

**Why Backend Signs Transactions**:

1. **Private Key Security**: Signing requires private keys that must never leave the server
2. **Account Management**: Backend controls accounts with funded balances
3. **Gas Fee Handling**: Backend pays transaction fees on behalf of users
4. **Nonce Management**: Prevents replay attacks by tracking transaction counts

**Flow**:
```
Flutter → "List product X"
         ↓
Backend → "I will create the transaction"
         → Loads private key from secure storage
         → Signs transaction
         → Submits to blockchain
         → Returns transaction hash
         ↓
Flutter ← "Transaction submitted: 0x5c8d..."
Rate Limiting & Abuse Prevention
The backend implements:

Request throttling: Max 100 requests per minute per IP
File size limits: Max 5MB for image uploads
Input validation: Sanitizes all user input
CORS policies: Restricts API access to known origins


🛠️ Local Development Setup
Prerequisites

Flutter SDK: 3.0+ (install guide)
Rust: 1.70+ (install guide)
Substrate Contracts Node: (install guide)
Cargo Contract: cargo install cargo-contract
Pinata Account: Free tier (sign up)

1. Clone Repository
bashgit clone https://github.com/yourusername/polkadot-marketplace.git
cd polkadot-marketplace
2. Start Polkadot Node
bashsubstrate-contracts-node --dev
This starts a local development blockchain at ws://127.0.0.1:9944.
3. Deploy Smart Contract
bashcd polkadot_contracts/marketplace
cargo contract build --release
Deploy via ui.use.ink:

Upload target/ink/marketplace.contract
Instantiate contract
Copy contract address

4. Configure Backend
bashcd backend/polkadot_marketplace_backend
Create .env file:
bashPINATA_JWT=your_pinata_jwt_token_here
PINATA_API_KEY=your_pinata_api_key
PINATA_SECRET_KEY=your_pinata_secret_key
POLKADOT_NODE_URL=ws://127.0.0.1:9944
CONTRACT_ADDRESS=5GTwSbGWYsuyMn5Ni8FnPd6Autpt4LKYYuyTcK95FRNvFSYJ
Get Pinata Credentials:

Go to Pinata Dashboard
API Keys → New Key → Create
Copy JWT token

5. Start Backend
bashcargo run
Server runs at http://127.0.0.1:8080.
Verify:
bashcurl http://127.0.0.1:8080/api/health
# Expected: {"status":"ok"}
6. Run Flutter App
bashcd ../../  # Back to project root
flutter pub get
flutter run -d linux  # or ios, android, web
```

### Project Structure
```
polkadot_marketplace/
├── lib/                          # Flutter app
│   ├── models/                   # Data models
│   ├── features/
│   │   ├── home/                 # Home screen & product listing
│   │   └── services/             # API clients
│   └── main.dart
├── backend/
│   └── polkadot_marketplace_backend/
│       ├── src/
│       │   ├── main.rs           # Server entry point
│       │   └── routes/
│       │       └── upload.rs     # IPFS upload endpoint
│       ├── Cargo.toml
│       └── .env                  # Secrets (not committed)
├── polkadot_contracts/
│   └── marketplace/
│       ├── lib.rs                # ink! smart contract
│       └── Cargo.toml
└── README.md
