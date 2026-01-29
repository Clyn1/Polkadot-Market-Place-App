🛒 Polkadot Marketplace — Rust-Powered Decentralized Marketplace
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

The application is built as a full-stack Web3 system using:

Flutter for the cross-platform mobile frontend

Rust for the backend API server

Rust (ink!) smart contracts on Polkadot

IPFS via Pinata for decentralized image storage

The Problem It Solves

Traditional e-commerce platforms suffer from major trust and centralization issues:

Centralized Control — Platforms can remove listings or freeze accounts

Data Ownership — Users do not own their data

High Fees — Intermediaries extract large transaction fees

Single Point of Failure — Server outages halt operations

Censorship — Platforms can remove content based on policies or location

Why Web3 & Decentralization

This project leverages Web3 to address these issues:

Immutable Ownership Records — Polkadot provides tamper-proof history

Decentralized Storage — IPFS removes reliance on centralized servers

Trustless Transactions — Smart contracts enforce rules automatically

Censorship Resistance — No single party can remove listings

Data Sovereignty — Users retain control of their content

🏗️ System Architecture
High-Level Overview
┌─────────────────┐
│                 │
│  Flutter App    │  ◄── Cross-platform mobile interface
│  (Frontend)     │
│                 │
└────────┬────────┘
         │ REST API (HTTP/JSON)
         ▼
┌─────────────────┐
│                 │
│  Rust Backend   │  ◄── Secure middleware layer
│  (API Server)   │      Handles secrets & integrations
│                 │
└────────┬────────┘
         │
         ├──────────────────────┬─────────────────────┐
         │                      │                     │
         ▼                      ▼                     ▼
┌──────────────┐       ┌──────────────┐      ┌──────────────┐
│ Pinata IPFS  │       │  Polkadot    │      │ Rust ink!    │
│   Gateway    │       │  Blockchain  │      │ Smart        │
│              │       │    Node      │      │ Contracts    │
└──────────────┘       └──────────────┘      └──────────────┘

Component Interaction Flow

User uploads product image via Flutter app

Flutter sends image to Rust backend via REST API

Rust backend uploads image to Pinata (IPFS)

Pinata returns IPFS CID (content hash)

Rust backend calls ink! smart contract with metadata + CID

Smart contract stores product data on-chain

Backend returns transaction hash to Flutter

Flutter displays product with image loaded from IPFS gateway

🦀 Rust Backend (Middleware Layer)
Why a Backend in Web3?

While Web3 emphasizes decentralization, production systems require a secure middleware layer.

The Rust backend provides:

Security

Secure storage of Pinata API keys

Secure blockchain private key handling

Protection against abuse and rate limiting

Abstraction

Hides blockchain complexity from Flutter

Provides clean REST APIs

Centralized error handling

Performance

Caching of blockchain queries

Connection pooling to Polkadot node

Efficient async handling via Rust

Judge-Friendly Architecture Explanation

The Rust backend acts as secure middleware between the Flutter app, the Polkadot blockchain, and IPFS via Pinata. It handles image uploads to IPFS, manages API keys securely, submits and queries smart contract transactions, and exposes clean REST APIs for the mobile app. This enables a production-style Web3 architecture where sensitive operations and external integrations are handled safely in Rust.

Without this backend, the mobile app would need to:

Embed API keys (security risk)

Implement SCALE codec logic

Manage blockchain signing

Maintain WebSocket blockchain connections

Backend Responsibilities
1. IPFS Integration
POST /api/upload/image


Receives base64 image

Uploads to Pinata

Returns IPFS CID

2. Blockchain Interaction

Encodes contract calls using SCALE codec

Signs transactions using backend-managed keys

Submits transactions via WebSocket

Waits for block finalization

Returns transaction hash

3. API Exposure
GET  /api/products
POST /api/products
GET  /api/products/:id
POST /api/products/:id/buy

4. Secret Management

Uses .env for Pinata + Polkadot secrets

Secrets never exposed to clients

Required secrets validated on startup

Technology Stack

Framework: Actix-web

HTTP Client: Reqwest

Serialization: Serde

Base64: base64 crate

Blockchain: WebSocket RPC to Polkadot node

🗂️ IPFS & Pinata Integration
What is IPFS?

IPFS is a peer-to-peer distributed file system that is:

Content-addressed

Immutable

Decentralized

Efficient via deduplication

What is Pinata?

Pinata is an IPFS pinning service that:

Ensures content availability

Provides public IPFS gateways

Simplifies IPFS integration

Prevents garbage collection

Why IPFS for Images?

Storing images on-chain is prohibitively expensive.

Storage Method	Cost	Suitability
On-Chain	Very High	❌
Central Server	Low	⚠️
IPFS	Low	✅
Upload & Retrieval

Backend uploads image to Pinata

Pinata returns CID

CID is stored on-chain

Image is accessed via:

https://gateway.pinata.cloud/ipfs/{CID}

⛓️ Blockchain & Smart Contracts (Rust ink!)
Role of Polkadot

Immutable records

Trustless execution

Transparent ownership

Scalable Substrate framework

Smart Contracts (ink! — Written in Rust)

ink! is a Rust-based smart contract framework for Polkadot that compiles to WebAssembly.

The marketplace contract is written in Rust, making this a fully Rust-powered Web3 stack.

Responsibilities:

Store product metadata

Store IPFS CIDs

Track ownership

Enforce purchase rules

Example (simplified):

#[ink::contract]
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
        ipfs_hash: String,
    ) -> Result<ProductId> {
        // Create product
    }

    #[ink(message)]
    pub fn purchase_product(
        &mut self,
        product_id: ProductId,
    ) -> Result<()> {
        // Transfer ownership
    }
}

On-Chain vs Off-Chain Data
Data Type	Storage	Reason
Product ID	On-chain	Indexing
Name & Price	On-chain	Business logic
Owner Address	On-chain	Ownership
IPFS CID	On-chain	Link to content
Product Image	IPFS	Large binary
Transaction History	On-chain	Audit trail
🔌 API Layer

Flutter communicates with backend via REST.

Example endpoints:

POST /api/upload/image

POST /api/products

GET /api/products

POST /api/products/:id/buy

Flutter uses the http package to consume these APIs.

🔒 Security Considerations
Why Secrets Never Touch Flutter

Mobile apps can be reverse engineered.
Embedding secrets is unsafe.

Risks:

APK decompilation

Memory inspection

Network sniffing

Accidental Git leaks

Backend-Managed Secrets

Stored in .env:

PINATA_JWT=...
POLKADOT_SEED_PHRASE=...
CONTRACT_ADDRESS=...


Secrets:

Never returned to client

Never committed to Git

Only accessible to backend

Transaction Signing

Backend signs all blockchain transactions to:

Protect private keys

Manage gas fees

Prevent replay attacks

Control funded accounts

🛠️ Local Development Setup
Prerequisites

Flutter SDK

Rust toolchain

Substrate Contracts Node

cargo-contract

Pinata account

Steps

Clone repo

Start contracts node

Build & deploy ink! contract

Configure backend .env

Run Rust backend

Run Flutter app

🏆 Hackathon Notes

This project demonstrates:

Full-stack Rust usage (backend + ink! smart contracts)

Production-style Web3 architecture

Secure middleware design

Decentralized storage + blockchain separation

Real-world mobile + blockchain integration

This is not a simple demo — it is a realistic Web3 system design.

🚀 Future Improvements

User authentication

Wallet-based signing

On-chain payments

Indexing for faster queries

Role-based access control

Marketplace analytics
