# Address Lookup Tables & Transaction Size

> Diagnose and fix ALT errors, transaction size limits, and versioned transaction issues.

## Transaction Size Limit

The maximum serialized transaction size is **1,232 bytes**. This includes:
- Signatures (64 bytes each)
- Message header (3 bytes)
- Account addresses (32 bytes each)
- Instruction data
- Address lookup table extensions (for versioned txs)

Legacy transactions can fit ~35 accounts before hitting the size limit. Versioned transactions with ALTs can reference up to **256 accounts** (128 writable + 128 read-only).

## Versioned Transactions

### Creating a Versioned Transaction with ALTs

```typescript
import {
  Connection, TransactionMessage, VersionedTransaction,
  AddressLookupTableAccount,
} from "@solana/web3.js";

// 1. Create/fetch the ALT
const slot = await connection.getSlot();
const [lookupTableIx, lookupTableAddress] =
  AddressLookupTableProgram.createLookupTable({
    authority: wallet.publicKey,
    payer: wallet.publicKey,
    slot,
  });

// 2. Send the create ALT transaction
const createTx = new Transaction().add(lookupTableIx);
await sendAndConfirmTransaction(connection, createTx, [wallet]);

// 3. Extend the ALT with addresses
const extendIx = AddressLookupTableProgram.extendLookupTable({
  lookupTable: lookupTableAddress,
  authority: wallet.publicKey,
  payer: wallet.publicKey,
  addresses: [address1, address2, address3, /* ... */],
});
await sendAndConfirmTransaction(connection, new Transaction().add(extendIx), [wallet]);

// 4. Fetch the ALT account
const lookupTableAccount = (await connection.getAddressLookupTable(lookupTableAddress)).value;

// 5. Build a versioned transaction
const message = TransactionMessage.compileToV0Message(
  [instruction1, instruction2],
  wallet.publicKey,
  [lookupTableAccount],
);
const tx = new VersionedTransaction(message);
tx.sign([wallet]);
```

### Fetching a Versioned Transaction

```typescript
// MUST use maxSupportedTransactionVersion
const tx = await connection.getTransaction(signature, {
  maxSupportedTransactionVersion: true,
});

// Access ALT-loaded accounts
const accountKeys = tx.transaction.message.getAccountKeys();
const altAccounts = accountKeys.accountKeysFromLookups;
// altAccounts.writable — writable accounts from ALTs
// altAccounts.readonly — read-only accounts from ALTs
```

## Common ALT Errors

### `Transaction version (0) is not supported`

**Error:**
```json
{"code": -32602, "message": "Transaction version (0) is not supported"}
```

**Cause:** You're fetching a versioned transaction without `maxSupportedTransactionVersion: true`.

**Fix:**
```typescript
const tx = await connection.getTransaction(signature, {
  maxSupportedTransactionVersion: true, // ADD THIS
});
```

### `AddressLookupTableAccountNotFound`

**Cause:** The ALT referenced in the transaction doesn't exist or has been deactivated/closed.

**Fix:**
1. Check if the ALT is still active:
```typescript
const altAccount = await connection.getAddressLookupTable(altAddress);
if (!altAccount.value) {
  console.log("ALT not found — may have been closed or never created");
}
```
2. If the ALT was deactivated, wait for the cool-down period (1 slot) and re-create it.

### `InvalidAccountIndex`

**Cause:** An instruction references an account index that doesn't exist in the account keys (including ALT-loaded accounts).

**Fix:** Ensure all accounts referenced by instructions are included in either the static account list or the ALT.

### `LookupTableAccountClosed`

**Cause:** The ALT was closed by its authority after the transaction was built but before it was processed.

**Fix:** Rebuild the transaction with a fresh ALT, or use a more durable ALT management strategy.

## Transaction Too Large

### Diagnosing Size Issues

```typescript
function checkTxSize(tx: VersionedTransaction): boolean {
  const serialized = tx.serialize();
  console.log(`Transaction size: ${serialized.length} bytes (max 1232)`);
  return serialized.length <= 1232;
}
```

### Reducing Transaction Size

| Strategy | Bytes Saved |
|---|---|
| Use ALTs to move accounts out of the static list | 32 per account |
| Reduce number of signers (each signature = 64 bytes) | 64 per signer |
| Shorten instruction data | varies |
| Use u8/u16 instead of u32/u64 where possible | 2-6 bytes per field |
| Remove unnecessary accounts | 32 per account |

### ALT Creation Best Practices

1. **Batch addresses:** Add all needed addresses in one `extendLookupTable` call to save transactions.
2. **Wait 1 slot:** ALTs become usable 1 slot after creation. Don't try to use them in the same transaction.
3. **Don't close ALTs prematurely:** Once closed, in-flight transactions referencing it will fail.
4. **Cache ALT accounts:** Fetch the ALT once and reuse the `AddressLookupTableAccount` object.

```typescript
// Good: fetch once, reuse
const lookupTableAccount = (await connection.getAddressLookupTable(altAddress)).value;
const messageV0 = TransactionMessage.compileToV0Message(
  instructions, payer, [lookupTableAccount]
);
```

## Versioned Transaction Gotchas

### 1. Can't Use `Transaction` with ALTs

Legacy `Transaction` objects don't support ALTs. You must use `VersionedTransaction`:

```typescript
// Wrong — legacy Transaction doesn't support ALTs
const tx = new Transaction().add(...instructions);

// Right — use VersionedTransaction
const message = TransactionMessage.compileToV0Message(
  instructions, payer, [lookupTableAccount]
);
const tx = new VersionedTransaction(message);
```

### 2. Signing is Different

```typescript
// Legacy: partial signing is flexible
tx.partialSign(signer);

// Versioned: must sign all at once or use specific signing flow
const tx = new VersionedTransaction(message);
tx.sign([walletKeypair]); // signs in-place
```

### 3. Simulation Requires Versioned Message

```typescript
const simulation = await connection.simulateTransaction(
  tx.message, // pass the message, not the full tx
  { replaceRecentBlockhash: true }
);
```

### 4. Wallet Adapter Support

Not all wallet adapters support versioned transactions. Check:

```typescript
if (wallet.supportedTransactionVersions?.includes(0)) {
  // Wallet supports v0 transactions
} else {
  // Fall back to legacy transaction
}
```

## ALT Deactivation Lifecycle

1. **Active:** ALT is usable in transactions
2. **Deactivated:** Authority calls `deactivateLookupTable` — ALT enters cool-down
3. **Frozen:** After ~513 slots, ALT becomes frozen (no more extensions)
4. **Closed:** After ~513 more slots, ALT is closed and purged

During the cool-down period, existing transactions can still reference the ALT, but new extensions are blocked.
