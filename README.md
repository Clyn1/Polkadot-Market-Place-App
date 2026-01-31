# Polkadot Marketplace App

## Rust Africa Hackathon 2026 Submission

A decentralized marketplace built on Polkadot using **Rust**, **ink! smart contracts**, a **Rust backend**, **Flutter mobile app**, and **IPFS (Pinata)** for decentralized storage.

---

## 🚀 Project Overview

Polkadot Marketplace is a full-stack Web3 application that allows users to:

* List products on-chain
* Upload product images to IPFS
* Store immutable product metadata via smart contracts
* Purchase products through blockchain transactions

This project demonstrates real-world usage of Rust across the entire stack.

---

## 🧩 Tech Stack

### Blockchain & Smart Contracts

* Polkadot
* ink! Smart Contracts (Written in Rust)
* Substrate-based contract deployment

### Backend (Rust)

* Rust (Actix-web / Axum)
* REST API Middleware
* Blockchain transaction encoding & signing
* Secure key management

### Mobile App

* Flutter
* Product listing UI
* Purchase flow
* IPFS image loading

### Storage

* IPFS
* Pinata API

---

## 🏗 Architecture Overview

Flutter App
↓
Rust Backend API
↓
Pinata (IPFS) + Polkadot Blockchain
↓
ink! Smart Contracts

The Rust backend acts as a secure middleware between the mobile app and the blockchain.

---

## 🔐 Why a Rust Backend?

The Rust backend is critical for production-grade Web3:

* Protects API keys (Pinata, blockchain keys)
* Handles transaction signing
* Prevents exposing secrets in mobile app
* Simplifies Flutter integration
* Adds validation and rate limiting

---

## 📦 Backend Responsibilities

* Secure storage of secrets
* REST API endpoints
* Blockchain transaction encoding
* SCALE encoding
* Contract interaction
* IPFS upload handling
* CID management

---

## 🧠 Smart Contracts (ink! + Rust)

The smart contracts are written in **Rust using ink!** and handle:

* Product registration
* Product ownership
* Immutable metadata references (IPFS CIDs)
* Purchase logic
* Event emission for UI updates

This ensures trustless and transparent marketplace logic.

---

## 📡 API Endpoints (Rust Backend)

* POST /api/upload → Upload image to IPFS
* POST /api/products → Create product on-chain
* GET /api/products → Fetch products
* POST /api/buy → Purchase product

---

## 🖼 IPFS & Pinata Integration

* Images are compressed in Flutter
* Sent to Rust backend
* Uploaded to Pinata via secure JWT
* CID returned
* CID stored on-chain via smart contract

This ensures decentralized, immutable media storage.

---

## ✅ Current Features

* Product listing with IPFS images
* Persistent on-chain product data
* Purchase flow
* Transaction simulation
* Smart contract deployed
* UI connected to blockchain

---

## 🏁 Hackathon Relevance

This project strongly aligns with Rust Africa Hackathon goals by:

* Using Rust for backend
* Writing ink! smart contracts in Rust
* Building real Polkadot integrations
* Demonstrating production-grade Web3 architecture

---

## 🛠 Setup (High Level)

1. Deploy ink! smart contracts
2. Run Rust backend server
3. Configure Pinata API keys
4. Run Flutter app

---

## 👤 Author

Clinton (Clyn)

Rust Developer | Mobile Developer | Web3 Builder

---

## 📄 License

MIT License

 ####RustAfricaHackathon

