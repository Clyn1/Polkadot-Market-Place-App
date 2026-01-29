</div>
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
A decentralized marketplace where users can:

✅ List products with images stored on IPFS
✅ Purchase items using blockchain transactions
✅ Verify ownership through immutable records
✅ Access content without centralized servers

The Problem It Solves
<table>
<tr>
<td width="25%"><b>❌ Centralized Control</b><br>Platforms remove listings arbitrarily</td>
<td width="25%"><b>❌ High Fees</b><br>15-30% transaction fees</td>
<td width="25%"><b>❌ Data Ownership</b><br>Users don't control their data</td>
<td width="25%"><b>❌ Single Point of Failure</b><br>Server outages halt operations</td>
</tr>
</table>
Our Solution
<table>
<tr>
<th>🔗 Polkadot</th>
<th>📁 IPFS</th>
<th>🦀 Rust</th>
<th>📱 Flutter</th>
</tr>
<tr>
<td>Immutable transaction records</td>
<td>Decentralized file storage</td>
<td>Secure middleware</td>
<td>Cross-platform UI</td>
</tr>
</table>

🏗️ System Architecture
High-Level Overview
<table>
<tr>
<td width="33%" align="center">
<b>📱 FLUTTER APP</b><br>
Cross-platform mobile interface<br>
(iOS, Android, Web, Desktop)
</td>
<td width="33%" align="center">
<b>🦀 RUST BACKEND</b><br>
Secure middleware layer<br>
Handles external integrations
</td>
<td width="33%" align="center">
<b>🌐 DECENTRALIZED</b><br>
IPFS • Polkadot • Smart Contracts
</td>
</tr>
</table>
Architecture Diagram
┌──────────────┐
│ Flutter App  │  ← User Interface
└──────┬───────┘
       │ REST API
       ↓
┌──────────────┐
│ Rust Backend │  ← Secure Middleware
└──┬─────┬─────┘
   │     │
   ↓     ↓
┌──────┐ ┌──────────┐
│ IPFS │ │ Polkadot │  ← Decentralized Infrastructure
└──────┘ └──────────┘
Component Interaction Flow
Step 1: User Uploads Product
📱 Flutter App → Selects image → Compresses to 800x800 @ 70% quality
Step 2: Image to IPFS
📱 Flutter → 🦀 Rust Backend → 📁 IPFS (Pinata) → Returns CID: QmXxx...
Step 3: Metadata to Blockchain
🦀 Rust Backend → Encodes transaction → ⛓️ Polkadot → Smart Contract stores data
Step 4: Product Listed
📱 Flutter App → Displays product → Loads image from IPFS gateway

🦀 Rust Backend (Middleware Layer)
Why a Backend in Web3?
<table>
<tr>
<th width="50%">❌ Without Backend (Typical Demo)</th>
<th width="50%">✅ With Rust Backend (Production)</th>
</tr>
<tr>
<td valign="top">
- API keys exposed in mobile app<br>
- Reverse engineering risk<br>
- No rate limiting<br>
- Complex blockchain SDK in Flutter<br>
- Battery drain from WebSocket connections
</td>
<td valign="top">
- Secrets stored server-side only<br>
- Secure key management<br>
- Request throttling & validation<br>
- Clean REST API for Flutter<br>
- Efficient HTTP calls
</td>
</tr>
</table>
Backend Responsibilities
<table>
<tr>
<th>🔐 Secret Management</th>
<th>📡 API Endpoints</th>
<th>⛓️ Blockchain Interaction</th>
<th>🖼️ IPFS Integration</th>
</tr>
<tr>
<td valign="top">
- Pinata JWT<br>
- Polkadot keys<br>
- Contract addresses<br>
- Never exposed
</td>
<td valign="top">
- POST /api/upload<br>
- POST /api/products<br>
- GET /api/products<br>
- POST /api/buy
</td>
<td valign="top">
- SCALE encoding<br>
- Transaction signing<br>
- Gas fee handling<br>
- Event listening
</td>
<td valign="top">
- Image compression<br>
- Pinata API calls<br>
- CID management<br>
- Gateway optimization
</td>
</tr>
</table>

💡 Architecture Explanation:
The Rust backend acts as secure middleware between the Flutter app, Polkadot blockchain, and IPFS. It handles image uploads to IPFS, manages API keys securely, submits and queries smart contract transactions, and exposes clean REST APIs. This enables production-grade Web3 architecture where sensitive operations are handled safely in Rust.


📁 IPFS & Pinata Integration
Why Not Store Images On-Chain?
<table>
<tr>
<th>Storage Method</th>
<th>Cost per MB</th>
<th>Speed</th>
<th>Decentralized</th>
</tr>
<tr>
<td><b>Polkadot On-Chain</b></td>
<td>💸 $10,000+</td>
<td>🐌 Slow</td>
<td>✅ Yes</td>
</tr>
<tr>
<td><b>AWS S3</b></td>
<td>💰 $0.023</td>
<td>⚡ Fast</td>
<td>❌ No</td>
</tr>
<tr>
<td><b>IPFS (Pinata)</b></td>
<td>💵 $0.15</td>
<td>⚡ Fast</td>
<td>✅ Yes</td>
</tr>
</table>
How IPFS Works
Traditional Web (Location-Based)
https://myserver.com/images/product.jpg
❌ Server down = image lost
IPFS (Content-Addressed)
ipfs://QmUNyjtUTFMq1PjQadUz3VsJfTcXeqUmfx5ySKSgoXEGt7
✅ Permanent, verifiable, decentralized
Upload Flow
<table>
<tr>
<th>Step 1</th>
<th>Step 2</th>
<th>Step 3</th>
<th>Step 4</th>
</tr>
<tr>
<td>📱 Flutter sends base64 image</td>
<td>🦀 Backend uploads to Pinata</td>
<td>📁 Pinata returns CID</td>
<td>🦀 Backend returns hash to Flutter</td>
</tr>
</table>
Gateway URL:
https://gateway.pinata.cloud/ipfs/{CID}

⛓️ Blockchain & Smart Contracts
What Lives Where
<table>
<tr>
<th>📦 On-Chain (Blockchain)</th>
<th>📁 Off-Chain (IPFS)</th>
</tr>
<tr>
<td valign="top">
- Product ID<br>
- Owner address<br>
- Price in DOT<br>
- IPFS hash (CID)<br>
- Availability status<br>
- Created timestamp
</td>
<td valign="top">
- Product image (2-5 MB)<br>
- High-resolution photos<br>
- Image metadata<br>
- EXIF data
</td>
</tr>
</table>
Smart Contract Functions
rust// List a new product
listProduct(name, description, price, ipfsHash) → ProductID

// Purchase a product
purchaseProduct(productId) → Transfers ownership + DOT

// Query product details
getProduct(productId) → Returns product struct

// Get all products
getAllProducts() → Returns array of products
Why Polkadot?
<table>
<tr>
<td><b>🔗 Interoperability</b><br>Parachains communicate seamlessly</td>
<td><b>⚡ Scalability</b><br>Shared security across chains</td>
<td><b>🔄 Upgradability</b><br>On-chain governance</td>
</tr>
</table>

🔌 API Layer
REST Endpoints
<table>
<tr>
<th>Endpoint</th>
<th>Method</th>
<th>Purpose</th>
</tr>
<tr>
<td><code>/api/upload/image</code></td>
<td>POST</td>
<td>Upload product image to IPFS</td>
</tr>
<tr>
<td><code>/api/products</code></td>
<td>POST</td>
<td>List new product on blockchain</td>
</tr>
<tr>
<td><code>/api/products</code></td>
<td>GET</td>
<td>Fetch all products</td>
</tr>
<tr>
<td><code>/api/products/:id/buy</code></td>
<td>POST</td>
<td>Purchase product</td>
</tr>
</table>
Example: Upload Image
Request:
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

🔒 Security Considerations
Three-Layer Security Model
<table>
<tr>
<th>Layer 1: Client (Flutter)</th>
<th>Layer 2: Backend (Rust)</th>
<th>Layer 3: Blockchain</th>
</tr>
<tr>
<td>🔓 Public<br>No secrets stored</td>
<td>🔐 Private<br>Manages all secrets</td>
<td>🔒 Immutable<br>Cryptographically secured</td>
</tr>
</table>
Why This Matters
Security RiskOur MitigationAPI Key ExposureKeys never leave backend .envTransaction TamperingBackend signs with private keyReplay AttacksNonce management in backendRate Limiting100 requests/min per IPInput ValidationSanitization at every layer

📦 Quick Start
Prerequisites
<table>
<tr>
<td><b>🎯 Flutter</b><br>v3.0+</td>
<td><b>🦀 Rust</b><br>v1.70+</td>
<td><b>⛓️ Substrate Node</b><br>Latest</td>
<td><b>📦 Cargo Contract</b><br>Latest</td>
</tr>
</table>
Installation Steps
1. Clone Repository
bashgit clone https://github.com/yourusername/polkadot-marketplace.git
cd polkadot-marketplace
2. Start Blockchain Node
bashsubstrate-contracts-node --dev
# Running at ws://127.0.0.1:9944
3. Deploy Smart Contract
bashcd polkadot_contracts/marketplace
cargo contract build --release
# Upload to ui.use.ink
4. Configure Backend
bashcd ../../backend/polkadot_marketplace_backend
echo "PINATA_JWT=your_jwt_here" > .env
echo "CONTRACT_ADDRESS=5GTw..." >> .env
5. Start Backend
bashcargo run
# Server at http://127.0.0.1:8080
6. Run Flutter App
bashcd ../..
flutter pub get
flutter run -d linux

🎯 Hackathon Notes
Why This Project Stands Out
<table>
<tr>
<th>Aspect</th>
<th>Implementation</th>
<th>Impact</th>
</tr>
<tr>
<td><b>🏗️ Architecture</b></td>
<td>Proper separation with Rust middleware</td>
<td>Production-ready, not demo</td>
</tr>
<tr>
<td><b>🔒 Security</b></td>
<td>No client secrets, server-side signing</td>
<td>Enterprise-grade</td>
</tr>
<tr>
<td><b>⚡ Performance</b></td>
<td>IPFS for files, blockchain for state</td>
<td>Fast despite decentralization</td>
</tr>
<tr>
<td><b>🧩 Tech Stack</b></td>
<td>Flutter + Rust + ink! + IPFS</td>
<td>Demonstrates versatility</td>
</tr>
</table>

🚀 Future Improvements
Phase 1: Production Ready

✅ JWT authentication
✅ Wallet integration
✅ On-chain DOT payments
✅ Search & filtering

Phase 2: Feature Expansion

🔄 Dispute resolution
🔄 IPNS support
🔄 Reputation system
🔄 Analytics dashboard

Phase 3: Ecosystem

🚧 Parachain deployment
🚧 NFT integration
🚧 Cross-chain payments
🚧 DAO governance


📊 Tech Stack
<table>
<tr>
<th>Layer</th>
<th>Technology</th>
<th>Purpose</th>
</tr>
<tr>
<td><b>Frontend</b></td>
<td>Flutter 3.0+</td>
<td>Cross-platform mobile UI</td>
</tr>
<tr>
<td><b>Backend</b></td>
<td>Rust (Actix-web)</td>
<td>Secure API server</td>
</tr>
<tr>
<td><b>Blockchain</b></td>
<td>Polkadot (Substrate)</td>
<td>Consensus & state</td>
</tr>
<tr>
<td><b>Smart Contracts</b></td>
<td>ink! v5 (Rust)</td>
<td>Business logic</td>
</tr>
<tr>
<td><b>Storage</b></td>
<td>IPFS (Pinata)</td>
<td>Decentralized files</td>
</tr>
</table>

📄 License
MIT License © 2026 - See LICENSE for details

📞 Contact
<div align="center">
Show Image
Show Image
Show Image
</div>

<div align="center">
⭐ Star this repo if you found it helpful! ⭐
Built with ❤️ for Web3
</div>

This version:
