# Resources

> RPC endpoints, explorers, and reference links for Solana transaction debugging.

## RPC Providers

| Provider | Endpoint | Notes |
|---|---|---|
| Solana (public) | `https://api.mainnet-beta.solana.com` | Rate-limited, no history beyond ~150 slots for some calls |
| Solana (devnet) | `https://api.devnet.solana.com` | Free, rate-limited |
| Helius | `https://mainnet.helius-rpc.com/?api-key=<KEY>` | Enhanced APIs, priority fee estimates, parsed tx |
| Triton | `https://<CLUSTER>.rpcpool.com` | High throughput, WebSocket support |
| QuickNode | `https://<ENDPOINT>.quicknode.pro` | Add-ons for DAS, trace APIs |
| Shyft | `https://rpc.shyft.to?api_key=<KEY>` | Parsed transactions, GSN |

## Key RPC Methods for Debugging

| Method | Purpose |
|---|---|
| `getTransaction` | Fetch full tx with logs, meta, inner instructions |
| `getSignatureStatuses` | Check confirmation status |
| `simulateTransaction` | Dry-run a tx without broadcasting |
| `getRecentPrioritizationFees` | Estimate priority fees |
| `getFeeForMessage` | Calculate transaction fee |
| `getLatestBlockhash` | Fresh blockhash + last valid block height |
| `getAddressLookupTable` | Fetch ALT account data |
| `getAccountInfo` | Check account state, owner, data |

### Helius Enhanced Methods

| Method | Purpose |
|---|---|
| `parseTransaction` (REST) | Human-readable tx events, token transfers |
| `getPriorityFeeEstimate` | Priority fee recommendation by level |
| `webhook` | Real-time tx notifications |

## Explorers

| Explorer | URL | Features |
|---|---|---|
| Solana Explorer | [explorer.solana.com](https://explorer.solana.com) | Official, logs, inner instructions |
| Solscan | [solscan.io](https://solscan.io) | Token analytics, account history |
| Solana Beach | [solanabeach.io](https://solanabeach.io) | Validator info, tx flow |
| X-Ray | [xray.solana.com](https://xray.solana.com) | Tx simulation, security analysis |

## Program IDs Quick Reference

| Program | ID |
|---|---|
| System | `11111111111111111111111111111111` |
| SPL Token | `TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA` |
| Token-2022 | `TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb` |
| Associated Token | `ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL` |
| Memo | `MemoSq4gqABAXKb96qnH8TysNcWxMyWCqXgDLGmfcHr` |
| Compute Budget | `ComputeBudget111111111111111111111111111111` |
| Address Lookup Table | `AddressLookupTab1e1111111111111111111111111` |
| BPF Loader (legacy) | `BPFLoader1111111111111111111111111111111111` |
| BPF Loader (upgradeable) | `BPFLoaderUpgradeab1e11111111111111111111111` |
| Ed25519 | `Ed25519SigVerify111111111111111111111111111` |
| Secp256k1 | `KeccakSecp256k11111111111111111111111111111` |

## Useful Libraries

| Library | Language | Purpose |
|---|---|---|
| `@solana/web3.js` | JS/TS | Core Solana SDK |
| `@solana/spl-token` | JS/TS | SPL Token interactions |
| `@solana/spl-token-2022` | JS/TS | Token-2022 support |
| `@coral-xyz/anchor` | JS/TS | Anchor client framework |
| `solana-sdk` | Rust | Rust SDK |
| `anchor-lang` | Rust | Anchor framework |
| `solana-cli` | CLI | Command-line tools |

## CLI Commands for Debugging

```bash
# Fetch a transaction
solana confirm <signature> -v

# Get transaction with logs
solana transaction <signature>

# Simulate a transaction from a file
solana transaction-confirm <signature> --verbose

# Check account info
solana account <address>

# Get recent priority fees
solana prioritization-fees

# Get blockhash
solana blockhash

# Check program logs (if running a local validator)
solana logs <program-id>
```

## Local Validator for Testing

```bash
# Start a local validator with program logging
solana-test-validator --log

# Load a program
solana-test-validator --bpf-program <program-id> <program.so>

# Clone mainnet accounts for local testing
solana-test-validator --clone <account-address> --url https://api.mainnet-beta.solana.com
```

## Anchor Error Reference

- [Anchor Error Codes](https://docs.rs/anchor-lang/latest/anchor_lang/error/enum.ErrorCode.html)
- [Anchor Source (errors.rs)](https://github.com/coral-xyz/anchor/blob/master/lang/src/error.rs)

## Solana Documentation

- [Transactions](https://solana.com/docs/core/transactions)
- [Runtime / Compute Budget](https://solana.com/docs/core/fees)
- [Address Lookup Tables](https://solana.com/docs/advanced/lookup-tables)
- [Versioned Transactions](https://solana.com/docs/advanced/versioned-transactions)

## Community Resources

- [Solana Stack Exchange](https://solana.stackexchange.com)
- [Anchor Discord](https://discord.gg/GvrWb6Z2)
- [Solana Discord](https://solana.com/discord)

## Related Kit Skills

- [solana-dev-skill](https://github.com/solanabr/solana-dev-skill) — core development skill
- [solana-game-skill](https://github.com/solanabr/solana-game-skill) — reference skill structure
- [sendaifun/skills](https://github.com/sendaifun/skills) — DeFi skills
- [helius-labs/core-ai](https://github.com/helius-labs/core-ai) — Helius RPC integration
