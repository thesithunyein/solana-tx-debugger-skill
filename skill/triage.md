# Triage: Fetching & Reading Transaction Data

> How to pull transaction data from RPC, extract errors, and prepare for diagnosis.

## Fetching a Confirmed Transaction

### Using `@solana/web3.js` (JavaScript/TypeScript)

```typescript
import { Connection, PublicKey } from "@solana/web3.js";

const connection = new Connection("https://api.mainnet-beta.solana.com");

const tx = await connection.getTransaction(signature, {
  maxSupportedTransactionVersion: 0, // REQUIRED for versioned txs
  commitment: "confirmed",
});

if (!tx) {
  console.log("Transaction not found — may be unconfirmed or expired");
  process.exit(1);
}

// Key fields to extract:
const meta = tx.meta;
const logs = meta?.logMessages ?? [];
const err = meta?.err; // null = success, otherwise the error object
const computeUnits = meta?.computeUnitsConsumed;
const fee = meta?.fee;
const innerInstructions = meta?.innerInstructions ?? [];
const loadedAddresses = meta?.loadedAddresses; // for versioned txs
const accounts = tx.transaction.message.getAccountKeys();
```

### Using Helius Enhanced API

```typescript
const response = await fetch(`https://api.helius-rpc.com/v0/transactions/?api-key=${HELIUS_KEY}`, {
  method: "POST",
  headers: { "Content-Type": "application/json" },
  body: JSON.stringify({ transactions: [signature] }),
});
const [tx] = await response.json();
// Helius provides parsed events, token transfers, and enriched error data
```

### Using `solana-rpc` (Rust)

```rust
let tx = rpc_client.get_transaction_with_config(
    &signature,
    RpcTransactionConfig {
        encoding: Some(UiTransactionEncoding::JsonParsed),
        commitment: Some(CommitmentConfig::confirmed()),
        max_supported_transaction_version: Some(true),
    },
).await?;
```

## Extracting the Error

### Error Object Structure

The `meta.err` field can be:
- `null` → transaction succeeded
- `"InsufficientFundsForRent"` → string error
- `{ "InstructionError": [0, "Custom": 4194604] }` → instruction-level error
- `{ "InstructionError": [0, "InsufficientFunds"] }` → known instruction error
- `{ "TransactionError": "BlockhashNotFound" }` → transaction-level error

### Parsing Instruction Errors

```typescript
function parseError(err: any): { instructionIndex: number; type: string; code?: number } {
  if (err?.InstructionError) {
    const [index, detail] = err.InstructionError;
    if (typeof detail === "object" && detail.Custom !== undefined) {
      return { instructionIndex: index, type: "Custom", code: detail.Custom };
    }
    return { instructionIndex: index, type: typeof detail === "string" ? detail : JSON.stringify(detail) };
  }
  if (err?.TransactionError) {
    return { instructionIndex: -1, type: err.TransactionError };
  }
  return { instructionIndex: -1, type: JSON.stringify(err) };
}
```

### Reading Program Logs

Logs are the richest source of diagnostic info. Key patterns:

```
Program <id> invoke [1]          # Program invoked (CPI depth in brackets)
Program <id> success             # Program succeeded
Program <id> failed: <reason>    # Program failed with reason
Program log: <message>           # Program emitted a log message
Program data: <hex>              # Program returned data
Program returned error: "<msg>"  # Program returned an error string
```

**Read logs bottom-up** — the last error line is usually the root cause.

### Extracting the Failing Program

```typescript
function findFailingProgram(logs: string[]): string | null {
  for (let i = logs.length - 1; i >= 0; i--) {
    const match = logs[i].match(/^Program (\S+) failed/);
    if (match) return match[1];
  }
  return null;
}
```

## Identifying the Program Framework

| Pattern in Logs | Framework |
|---|---|
| `Program log: AnchorError` | Anchor |
| `Program log: <Error>#<code>` with `#[error_code]` | Anchor |
| `Program returned error: "custom program error: 0x..."` | Anchor (raw) |
| `Program log: Instruction fell through` | Raw BPF (no error handler) |
| No `Program log:` lines, just `failed` | System or low-level BPF |

## Handling Versioned Transactions

Versioned transactions (with ALTs) require special handling:

```typescript
// MUST set maxSupportedTransactionVersion: 0
const tx = await connection.getTransaction(signature, {
  maxSupportedTransactionVersion: 0,
});

// Account keys include ALT-loaded addresses
const accountKeys = tx.transaction.message.getAccountKeys();
// accountKeys.staticAccountKeys — original signers/writable
// accountKeys.accountKeysFromLookups — ALT-loaded addresses
```

If you get `{"code": -32602, "message": "Transaction version (0) is not supported"}`, you forgot `maxSupportedTransactionVersion`.

## Checklist Before Diagnosis

- [ ] Fetched full transaction with `maxSupportedTransactionVersion: 0`
- [ ] Extracted `meta.err` and parsed the error type/code
- [ ] Read all `logMessages` (bottom-up)
- [ ] Identified the failing program and its framework (Anchor/SPL/raw BPF)
- [ ] Checked `innerInstructions` for CPI-level failures
- [ ] Noted `computeUnitsConsumed` vs limit
- [ ] Listed all accounts passed to the failing instruction
