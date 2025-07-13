# STX Collective NFT

A Clarity smart contract for splitting expensive NFTs into smaller, tradeable shares on the Stacks blockchain. This enables collective ownership of high-value NFTs by allowing multiple users to purchase fractional shares.

## 🌟 Features

- **Fractionalize Any NFT**: Split expensive NFTs into any number of shares
- **Decentralized Trading**: Buy, sell, and transfer shares directly on-chain
- **Ownership Tracking**: Real-time tracking of share ownership and percentages
- **Flexible Pricing**: Set custom share prices in STX
- **Secure Design**: Built-in safety measures and emergency controls
- **Gas Efficient**: Optimized for minimal transaction costs

## 🏗️ Architecture

The contract uses three main data structures:

1. **Collectives**: Store NFT and share information
2. **Shares**: Track individual ownership amounts
3. **Metadata**: Store collective names and descriptions

## 📋 Contract Functions

### Core Functions

#### `create-collective`
Create a new NFT collective with fractional shares.

```clarity
(create-collective nft-contract nft-token-id total-shares share-price name description)
```

**Parameters:**
- `nft-contract`: Principal of the NFT contract
- `nft-token-id`: Token ID of the NFT
- `total-shares`: Total number of shares to create
- `share-price`: Price per share in STX (microSTX)
- `name`: Collective name (max 64 characters)
- `description`: Collective description (max 256 characters)

**Returns:** `collective-id` of the newly created collective

#### `buy-shares`
Purchase shares of a collective with STX.

```clarity
(buy-shares collective-id share-amount)
```

**Parameters:**
- `collective-id`: ID of the collective
- `share-amount`: Number of shares to purchase

**Returns:** Number of shares purchased

#### `sell-shares`
Sell shares back to the contract for STX.

```clarity
(sell-shares collective-id share-amount)
```

**Parameters:**
- `collective-id`: ID of the collective
- `share-amount`: Number of shares to sell

**Returns:** Number of shares sold

#### `transfer-shares`
Transfer shares to another user.

```clarity
(transfer-shares collective-id share-amount recipient)
```

**Parameters:**
- `collective-id`: ID of the collective
- `share-amount`: Number of shares to transfer
- `recipient`: Principal of the recipient

**Returns:** Boolean success

### Read-Only Functions

#### `get-collective`
Get information about a collective.

```clarity
(get-collective collective-id)
```

#### `get-shares`
Get share ownership for a user.

```clarity
(get-shares collective-id owner)
```

#### `get-share-percentage`
Get ownership percentage (in basis points).

```clarity
(get-share-percentage collective-id owner)
```

#### `get-collective-metadata`
Get collective name and description.

```clarity
(get-collective-metadata collective-id)
```

### Admin Functions

#### `deactivate-collective`
Deactivate a collective (creator only).

```clarity
(deactivate-collective collective-id)
```

#### `emergency-pause`
Emergency pause for a collective (contract owner only).

```clarity
(emergency-pause collective-id)
```

## 🚀 Usage Examples

### Creating a Collective

```clarity
;; Create a collective for an expensive NFT
(contract-call? .stx-collective-nft create-collective
  'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7.my-nft  ;; NFT contract
  u1                                                      ;; Token ID
  u1000                                                   ;; 1000 shares
  u100000                                                 ;; 0.1 STX per share
  "Expensive Ape #1"                                      ;; Name
  "Fractionalized Bored Ape NFT"                          ;; Description
)
```

### Buying Shares

```clarity
;; Buy 10 shares of collective #1
(contract-call? .stx-collective-nft buy-shares u1 u10)
```

### Checking Ownership

```clarity
;; Check how many shares I own
(contract-call? .stx-collective-nft get-shares u1 tx-sender)

;; Check my ownership percentage
(contract-call? .stx-collective-nft get-share-percentage u1 tx-sender)
```

### Transferring Shares

```clarity
;; Transfer 5 shares to another user
(contract-call? .stx-collective-nft transfer-shares 
  u1 
  u5 
  'SP2J6ZY48GV1EZ5V2V5RB9MP66SW86PYKKNRV9EJ7
)
```

## 💰 Economics

- **Share Price**: Set by the collective creator in STX
- **Trading**: Direct peer-to-peer trading through the contract
- **Liquidity**: Users can sell shares back to the contract at the original price
- **No Fees**: Currently no trading fees (can be added in future versions)

## 🔒 Security Features

- **Input Validation**: All parameters are validated before execution
- **Authorization Checks**: Only authorized users can perform specific actions
- **Safe STX Transfers**: Uses built-in STX transfer functions
- **Emergency Controls**: Contract owner can pause collectives if needed
- **Active Status**: Only active collectives can be traded

## 🛠️ Error Codes

| Code | Description |
|------|-------------|
| u100 | Owner only |
| u101 | Not found |
| u102 | Insufficient shares |
| u103 | Invalid amount |
| u104 | Already exists |
| u105 | Not authorized |
| u106 | Transfer failed |
| u107 | Invalid shares |

## 📊 Data Structures

### Collective Info
```clarity
{
  nft-contract: principal,
  nft-token-id: uint,
  total-shares: uint,
  share-price: uint,
  creator: principal,
  active: bool
}
```

### Share Ownership
```clarity
{
  amount: uint
}
```

### Collective Metadata
```clarity
{
  name: (string-ascii 64),
  description: (string-ascii 256)
}
```

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Submit a pull request with tests
4. Ensure all security checks pass

Built with ❤️ for the Stacks ecosystem