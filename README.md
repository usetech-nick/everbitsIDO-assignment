# Everbits IDO – Max Tokens Per Wallet

This repository contains my solution for adding a **maximum token allocation per wallet** to the Everbits IDO smart contract.

## Problem
In this IDO design, users contribute ETH during the presale, but the **token price is determined only after the IDO ends** (proportional allocation).  
Because of this, a simple ETH-per-wallet cap is insufficient.

## Solution
I enforced the wallet cap using a **worst-case token price** approach:
- Assume the IDO reaches its **hard cap**
- Calculate the maximum possible token allocation for a wallet
- Revert contributions that would exceed `maxTokensPerWallet`

This guarantees that **no wallet can ever receive more than the allowed token limit**, regardless of how the IDO ends.

## Implementation
- Added `maxTokensPerWallet` to `StandardIDOParams`
- Enforced the cap inside `EverbitsIDO.contribute()`
- Fully enforced on-chain (no frontend reliance)

## Demo
The solution is deployed and demonstrated on **Sepolia** using a script that:
1. Creates a Mini IDO
2. Accepts a valid contribution
3. Reverts when the wallet cap is exceeded

    ```bash
    npx hardhat run scripts/demoMiniIDO.ts --network sepolia
    
## Status
✅ Implemented
✅ Deployed on Sepolia
✅ Demonstrated via Loom
