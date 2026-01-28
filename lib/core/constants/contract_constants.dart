class ContractConstants {
  // 🔗 WebSocket endpoint
  static const String nodeUrl = 'ws://127.0.0.1:9944';
  
  // 📝 Contract address (replace with your actual address)
  static const String contractAddress = '5FHneW46xGXgs5mUiveU4sbTyGBzmstUspZC92UhjJM694ty';
  
  // 👤 Alice's account
  static const String aliceAddress = '5GrwvaEF5zXb26Fz9rcQpDWS57CtERHpNehXCPcNoHGKutQY';
  static const String aliceSeed = '//Alice';
  
  // 👤 Bob's account
  static const String bobAddress = '5FHneW46xGXgs5mUiveU4sbTyGBzmstUspZC92UhjJM694ty';
  static const String bobSeed = '//Bob';
  
  // 💰 Gas limit (removed 'const' keyword)
  static final BigInt gasLimit = BigInt.from(10000000000);
  
  // 💎 Storage deposit limit (removed 'const' keyword)
  static final BigInt storageDepositLimit = BigInt.from(1000000000000);
}