# Transaction Simulation

> Use `simulateTransaction` to debug failures before broadcasting, or to diagnose a tx that won't land.

## When to Simulate

- **Before sending:** Catch errors without spending SOL on failed transactions
- **Debugging a failed tx:** Reconstruct and simulate to get full logs
- **Estimating compute:** Get exact CU usage before setting limits
- **Dry-run CPIs:** See what inner instructions would execute

## Simulating with `@solana/web3.js`

### Basic Simulation

```typescript
import { Connection, Transaction, VersionedTransaction } from "@solana/web3.js";

// For legacy transactions
const simulation = await connection.simulateTransaction(transaction, {
  replaceRecentBlockhash: true, // use a recent blockhash even if tx has old one
  sigVerify: false, // skip signature verification for simulation
  commitment: "confirmed",
});

if (simulation.value.err) {
  console.log("Simulation failed:", simulation.value.err);
  console.log("Logs:", simulation.value.logs);
  console.log("Compute units:", simulation.value.unitsConsumed);
  console.log("Consumed accounts:", simulation.value.accounts);
} else {
  console.log("Simulation succeeded");
  console.log("Compute units:", simulation.value.unitsConsumed);
}
```

### Simulating a Versioned Transaction

```typescript
// For versioned transactions, pass the message
const simulation = await connection.simulateTransaction(
  versionedTx.message,
  {
    replaceRecentBlockhash: true,
    sigVerify: false,
  }
);
```

### Simulating Raw Instructions (Without Building a Full Tx)

```typescript
import { TransactionMessage, VersionedTransaction } from "@solana/web3.js";

const message = TransactionMessage.compileToV0Message(
  [instruction1, instruction2],
  payerPublicKey,
  [lookupTableAccount],
);
const vtx = new VersionedTransaction(message);

const simulation = await connection.simulateTransaction(vtx.message, {
  replaceRecentBlockhash: true,
  sigVerify: false,
});
```

## Using Helius Enhanced Simulation

Helius provides richer simulation results including pre/post token balances and parsed events:

```typescript
const response = await fetch(`https://mainnet.helius-rpc.com/?api-key=${HELIUS_KEY}`, {
  method: "POST",
  headers: { "Content-Type": "application/json" },
  body: JSON.stringify({
    jsonrpc: "2.0",
    id: "1",
    method: "simulateTransaction",
    params: [{
      transaction: serializedTxBase64,
      encoding: "base64",
      config: {
        replaceRecentBlockhash: true,
        commitment: "confirmed",
        accounts: {
          encoding: "base64",
          addresses: [account1, account2],
        },
      },
    }],
  }),
});
const result = (await response.json()).result.value;
```

## Interpreting Simulation Results

### Error Types

```typescript
const err = simulation.value.err;

if (typeof err === "string") {
  // Transaction-level error: "BlockhashNotFound", "InsufficientFundsForFee"
  console.log("Transaction error:", err);
} else if (err?.InstructionError) {
  const [index, detail] = err.InstructionError;
  if (typeof detail === "object" && detail.Custom !== undefined) {
    console.log(`Instruction #${index} failed with custom error: 0x${detail.Custom.toString(16)}`);
  } else {
    console.log(`Instruction #${index} failed: ${detail}`);
  }
}
```

### Reading Simulation Logs

Simulation logs follow the same format as confirmed transaction logs:

```
Program <id> invoke [1]
Program log: <message>
Program <id> consumed 12345 of 200000 compute units
Program <id> failed: <reason>
```

**Key: Read bottom-up.** The last `failed:` line is the root cause.

### Compute Units from Simulation

```typescript
const cu = simulation.value.unitsConsumed;
console.log(`Compute units: ${cu} / 200,000 (default)`);
if (cu > 200_000) {
  console.log("→ Need to setComputeUnitLimit to at least", Math.ceil(cu / 1000) * 1000);
}
```

## Common Simulation Errors

### `BlockhashNotFound`

**Cause:** The blockhash in the transaction is too old (>150 slots ~60 seconds).

**Fix:** Use `replaceRecentBlockhash: true` in simulation, or fetch a fresh blockhash:

```typescript
const { blockhash } = await connection.getLatestBlockhash();
transaction.recentBlockhash = blockhash;
```

### `InsufficientFundsForFee`

**Cause:** The fee payer doesn't have enough SOL for the transaction fee.

**Fix:** Check the payer's balance and airdrop/fund if needed:

```typescript
const balance = await connection.getBalance(payer);
const fee = await connection.getFeeForMessage(message);
if (balance < fee) {
  console.log(`Need ${fee - balance} more lamports`);
  // Devnet: await connection.requestAirdrop(payer, fee);
}
```

### `AccountInUse`

**Cause:** A lock on one of the accounts is held by another in-flight transaction.

**Fix:** Wait and retry, or use a different account. This is a transient error.

## Simulation vs. Confirmed Transaction

| Aspect | Simulation | Confirmed Tx |
|---|---|---|
| Costs SOL? | No | Yes (fee) |
| Gets logs? | Yes | Yes (if `getTransaction`) |
| Gets inner instructions? | Yes | Yes |
| Gets compute units? | Yes | Yes |
| Blockhash validity? | Can bypass with `replaceRecentBlockhash` | Must be valid |
| Account state? | Current at simulation time | At inclusion slot |

**Tip:** Always simulate before sending high-value or complex transactions. It's free and catches 90% of errors.

## Reconstructing a Failed Transaction for Simulation

If you have a failed tx signature and want to re-simulate:

```typescript
// 1. Fetch the failed tx
const failedTx = await connection.getTransaction(signature, {
  maxSupportedTransactionVersion: 0,
});

// 2. Reconstruct the message
const message = VersionedTransaction.deserialize(
  failedTx.transaction.encode() // or however you get the raw bytes
).message;

// 3. Re-simulate with fresh blockhash
const simulation = await connection.simulateTransaction(message, {
  replaceRecentBlockhash: true,
  sigVerify: false,
});

// 4. Compare logs
console.log("Original logs:", failedTx.meta?.logMessages);
console.log("Simulation logs:", simulation.value?.logs);
```
