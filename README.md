# Decentralized Marketplace (Rust + Flutter + Polkadot + IPFS)

## Project Description

This project is a full-stack, decentralized marketplace that enables users to upload product images, register products, and manage ownership using Web3 technologies. It is built with:

* **Flutter** — Mobile frontend application
* **Rust** — Backend API server (middleware layer)
* **Polkadot Blockchain** — Smart contracts written in **Rust using ink!**
* **IPFS via Pinata** — Decentralized file storage for product images

The system allows users to upload product images from a mobile app, store those images on IPFS, and store product metadata and ownership information on the Polkadot blockchain via ink! smart contracts.

### Problem It Solves

Traditional marketplaces rely on centralized servers for:

* Image storage
* Product ownership records
* Platform trust

This creates single points of failure, censorship risks, and limited transparency.

This project solves these problems by:

* Using **decentralized storage (IPFS)** for product images
* Using **blockchain smart contracts** for product metadata and ownership
* Using **Rust backend middleware** to securely connect mobile apps to Web3 infrastructure

### Why Web3 & Decentralization

Web3 enables:

* Trustless ownership verification
* Tamper-resistant product records
* Censorship-resistant image storage
* Transparent marketplace logic via smart contracts

This architecture removes reliance on a single centralized authority and increases transparency and security.

---

## System Architecture (High-Level)

The system is composed of four main layers:

1. Flutter Mobile App (Frontend)
2. Rust Backend API Server (Middleware)
3. Polkadot Blockchain (ink! Smart Contracts written in Rust)
4. IPFS via Pinata (Decentralized Storage)

### Architecture Flow

```
Flutter Mobile App
        |
        v
Rust Backend API Server (Rust)
        |
        |----> Pinata API (IPFS)  -> Stores images, returns CID
        |
        |----> Polkadot Node -> ink! Smart Contracts (Rust)
```

Text-based flow:

**Flutter App → Rust Backend → (Pinata IPFS + Polkadot Blockchain)**

The Flutter app never talks directly to Pinata or the blockchain. All sensitive operations go through the Rust backend.

---

## Rust Backend (Middleware Layer) — Core Architecture

The Rust backend is a critical production-style middleware layer that securely connects the mobile frontend to decentralized infrastructure.

It acts as the trusted bridge between:

* Flutter mobile application
* Pinata IPFS API
* Polkadot blockchain (ink! smart contracts written in Rust)

### Responsibilities of the Rust Backend

The Rust backend is responsible for:

* Exposing REST APIs to the Flutter app
* Handling Pinata API integration
* Uploading images to IPFS
* Managing API keys and secrets securely
* Submitting and querying smart contract transactions
* Abstracting blockchain complexity away from the mobile app

### Judge-Friendly Conceptual Explanation

> The Rust backend acts as a secure middleware between the Flutter app, the Polkadot blockchain, and IPFS via Pinata. It handles image uploads to IPFS, manages API keys securely, submits and queries smart contract transactions, and exposes clean REST APIs for the mobile app. This enables a production-style Web3 architecture where sensitive operations and external integrations are handled safely in Rust.

This design mirrors real-world Web3 production systems, where:

* Mobile apps remain lightweight
* Sensitive credentials never live on the client
* Blockchain and storage integrations are handled by secure backend services

---

## IPFS & Pinata Integration

### What is Pinata

Pinata is a managed IPFS pinning service that provides:

* Reliable IPFS pinning
* API-based file uploads
* Persistent availability of IPFS content

### Why IPFS is Used

IPFS (InterPlanetary File System) is used to:

* Decentralize image storage
* Avoid centralized image servers
* Enable content-addressed storage using hashes (CIDs)

### How the Rust Backend Uploads Files

1. Flutter app sends image file to Rust backend
2. Rust backend authenticates with Pinata using API keys
3. Rust backend uploads image to Pinata
4. Pinata returns an IPFS CID (Content Identifier)
5. Rust backend returns the CID to Flutter

### IPFS CID Handling

* The CID uniquely represents the image content
* The CID is stored in smart contract state on-chain
* Anyone can retrieve the image using the CID via IPFS gateways

### Why Images Are Not Stored On-Chain

Storing images directly on-chain is:

* Extremely expensive
* Inefficient
* Not scalable

Instead:

* Images are stored off-chain on IPFS
* Only the CID (hash) is stored on-chain

This is a standard Web3 architecture pattern.

---

## Blockchain & Smart Contracts (ink! + Rust)

### Role of Polkadot

Polkadot provides:

* A scalable blockchain environment
* Smart contract execution
* Secure decentralized state management

### Role of ink! Smart Contracts (Written in Rust)

The smart contracts are written in **Rust using ink!**, Polkadot’s smart contract framework.

ink! allows developers to write smart contracts using Rust syntax and tooling.

These smart contracts handle:

* Product registration
* Product metadata storage
* Ownership records
* On-chain verification of product data

### On-Chain vs Off-Chain Data

On-chain (Polkadot + ink!):

* Product ID
* Product name
* Owner address
* IPFS CID (image hash)

Off-chain (IPFS):

* Actual product images

### Backend Interaction with Smart Contracts

The Rust backend:

* Connects to a Polkadot node
* Submits transactions to ink! smart contracts
* Queries contract state
* Handles transaction signing

This keeps blockchain logic out of the mobile app and centralized in a secure Rust service.

---

## API Layer (Backend → Frontend)

The Rust backend exposes REST APIs that the Flutter app consumes.

### Example Endpoints (Conceptual)

* `POST /upload-image`

  * Uploads image to IPFS via Pinata
  * Returns IPFS CID

* `POST /create-product`

  * Submits smart contract transaction
  * Stores product metadata + CID on-chain

* `GET /products`

  * Queries smart contract state
  * Returns list of registered products

### Flutter Integration

The Flutter app:

* Calls REST APIs
* Never handles private keys
* Never stores API secrets
* Displays blockchain-backed product data

---

## Security Considerations

### API Key Security

* Pinata API keys are stored only in the Rust backend
* API keys are never embedded in the Flutter app

### Blockchain Transaction Security

* The Rust backend handles transaction signing
* Private keys are stored securely on the server
* The Flutter app never has direct signing authority

### Why This Matters

This prevents:

* Key leakage from mobile apps
* Unauthorized access to Pinata
* Direct user-side manipulation of blockchain logic

This matches real-world Web3 backend security practices.

---

## Local Development Setup

### Rust Backend

```bash
cd backend
cargo run
```

Configure environment variables:

```bash
PINATA_API_KEY=your_key
PINATA_API_SECRET=your_secret
POLKADOT_NODE_URL=ws://localhost:9944
```

### Flutter App

```bash
cd mobile
flutter pub get
flutter run
```

Configure backend base URL in Flutter.

### Polkadot Node

Run a local Polkadot / Substrate node or connect to a testnet.

Deploy ink! smart contracts and update backend contract addresses.

---

## Hackathon / Judge Notes

This project demonstrates:

* Full-stack Web3 architecture
* Rust backend as production-grade middleware
* Rust-based ink! smart contracts
* Decentralized storage with IPFS
* Clean separation of on-chain and off-chain responsibilities

This is not a simple demo app. It reflects how real-world Web3 systems are designed with:

* Secure backend services
* Smart contract integration
* Decentralized storage
* Mobile-friendly APIs

---

## Future Improvements

* User authentication & identity
* Wallet integration (Polkadot wallets)
* On-chain payments and escrow
* Indexing for faster queries
* Caching & performance optimization
* Role-based access control

---

## Summary

This project showcases a serious, production-style Web3 system built around Rust:

* Rust backend API server
* Rust-based ink! smart contracts
* Secure middleware architecture
* Decentralized storage with IPFS
* Mobile-first Flutter frontend
