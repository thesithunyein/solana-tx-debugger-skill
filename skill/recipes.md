# Error Recipes: Cause → Fix

> 20+ real-world Solana transaction errors with their root causes and concrete fixes. This is the core value of the skill.

## How to Use

Find your error in the table of contents, jump to the recipe, apply the fix. Each recipe includes: the error as it appears in logs, the root cause, and a runnable fix.

---

## Table of Contents

1. [BlockhashNotFound](#1-blockhashnotfound)
2. [ComputationalBudgetExceeded](#2-computationalbudgetexceeded)
3. [Anchor: AccountNotSigner (0x1006)](#3-accountnotsigner)
4. [Anchor: AccountDiscriminatorMismatch (0x1013)](#4-accountdiscriminatormismatch)
5. [Anchor: ConstraintSeeds / PDA Mismatch (0x100e)](#5-constraintseeds)
6. [Anchor: InsufficientFundsForRent (0x1016)](#6-insufficientfundsforrent)
7. [Anchor: UninitializedAccount (0x100b)](#7-uninitializedaccount)
8. [SPL Token: InsufficientFunds (0x1)](#8-spl-insufficientfunds)
9. [SPL Token: OwnerMismatch (0x3)](#9-spl-ownermismatch)
10. [SPL Token: AccountNotInitialized (0x6)](#10-spl-notinitialized)
11. [Token-2022: Transfer Fee InsufficientFunds](#11-token2022-transferfee)
12. [Token-2022: AccountFrozen (0x16)](#12-accountfrozen)
13. [System: ResultWithNegativeLamports (0x1)](#13-negativelamports)
14. [System: UnbalancedInstruction (0x7)](#14-unbalancedinstruction)
15. [Instruction fell through (0x0)](#15-instructionfellthrough)
16. [Transaction too large (>1232 bytes)](#16-txtoolarge)
17. [Transaction version not supported](#17-versionnotsupported)
18. [ATA: AccountAlreadyInitialized (0x0)](#18-ata-alreadyinitialized)
19. [Priority fee too low / tx not landing](#19-txnotlanding)
20. [CPI depth exceeded](#20-cpidepth)
21. [AccountAlreadyInUse](#21-accountinuse)
22. [Custom program error with unknown code](#22-unknowncustom)

---

## 1. BlockhashNotFound

**Log:**
```
TransactionError: BlockhashNotFound
```

**Cause:** The blockhash used in the transaction is expired (older than ~150 slots / ~60 seconds).

**Fix:**
```typescript
// Always fetch a fresh blockhash right before signing
const { blockhash, lastValidBlockHeight } = await connection.getLatestBlockhash();
transaction.recentBlockhash = blockhash;

// Send and confirm with block height check
const sig = await sendAndConfirmTransaction(connection, transaction, [signer], {
  commitment: "confirmed",
  // This will retry if blockhash expires
});
```

**Prevention:** Use a transaction sender that auto-refreshes blockhashes (like `@solana/wallet-adapter` or Helius Smart WebSockets).

---

## 2. ComputationalBudgetExceeded

**Log:**
```
Program ComputeBudget111111111111111111111111111111 failed: ComputationalBudgetExceeded
```

**Cause:** Transaction consumed more CU than the limit (default 200,000).

**Fix:**
```typescript
import { ComputeBudgetProgram } from "@solana/web3.js";

const tx = new Transaction().add(
  ComputeBudgetProgram.setComputeUnitLimit({ units: 600_000 }),
  ComputeBudgetProgram.setComputeUnitPrice({ microLamports: 1_000 }),
  // ... your instructions
);
```

**Also:** Optimize the program — see [`compute-budget.md`](compute-budget.md) for optimization tips.

---

## 3. AccountNotSigner

**Log:**
```
Program returned error: "custom program error: 0x1006"
```

**Cause:** Anchor error #6 — an account marked `Signer` in `#[derive(Accounts)]` was not passed as a signer.

**Fix:**
```typescript
// Ensure the signer keypair is included in signers
await program.methods.myInstruction()
  .accounts({
    authority: wallet.publicKey,
  })
  .signers([wallet]) // or ensure wallet is the transaction signer
  .rpc();
```

**In Anchor (Rust):**
```rust
// If the account shouldn't be a signer, change the constraint:
#[derive(Accounts)]
pub struct MyInstruction<'info> {
    // Change from:
    // pub authority: Signer<'info>,
    // To (if not needed as signer):
    pub authority: Account<'info, User>,
}
```

---

## 4. AccountDiscriminatorMismatch

**Log:**
```
Program log: AnchorError: Error: AccountDiscriminatorMismatch
Program returned error: "custom program error: 0x1013"
```

**Cause:** The account passed doesn't match the expected Anchor account type (wrong 8-byte discriminator).

**Fix:**
```typescript
// Verify the account type before calling
const accountInfo = await connection.getAccountInfo(pda);
if (!accountInfo) {
  throw new Error("Account doesn't exist");
}

// Check discriminator (first 8 bytes)
const expectedDisc = Buffer.from(
  createHash('sha256').update('account:MyType').digest().slice(0, 8)
);
if (!accountInfo.data.slice(0, 8).equals(expectedDisc)) {
  throw new Error("Wrong account type — expected MyType");
}
```

---

## 5. ConstraintSeeds

**Log:**
```
Program log: AnchorError: Error: ConstraintSeeds
Program returned error: "custom program error: 0x100e"
```

**Cause:** PDA derived from seeds doesn't match the account passed.

**Fix:**
```typescript
// Verify PDA derivation matches
const [expectedPda] = PublicKey.findProgramAddressSync(
  [Buffer.from("my_seed"), authority.toBuffer()],
  programId
);

if (passedAccount.equals(expectedPda)) {
  // Correct — proceed
} else {
  // Wrong — use expectedPda instead
  console.log("Use this PDA:", expectedPda.toBase58());
}
```

**Common seed bugs:**
- Mismatched encoding (e.g., `Buffer.from("seed")` vs `new TextEncoder().encode("seed")` — these are the same, but `bs58.decode("seed")` is different)
- Missing a seed component (e.g., forgot to include mint address)
- Wrong seed string (typo)

---

## 6. InsufficientFundsForRent

**Log:**
```
Program log: AnchorError: Error: InsufficientFundsForRent
Program returned error: "custom program error: 0x1016"
```

**Cause:** Account balance would fall below rent-exempt minimum after the operation.

**Fix:**
```typescript
// Calculate rent-exempt minimum
const rentExempt = await connection.getMinimumBalanceForRentExemption(
  ACCOUNT_SIZE // size in bytes
);

// Fund the account before the operation
const fundIx = SystemProgram.transfer({
  fromPubkey: payer,
  toPubkey: targetAccount,
  lamports: rentExempt,
});

// Or include funding in the same transaction
const tx = new Transaction().add(fundIx, yourInstruction);
```

---

## 7. UninitializedAccount

**Log:**
```
Program log: AnchorError: Error: UninitializedAccount
Program returned error: "custom program error: 0x100b"
```

**Cause:** Account exists but hasn't been initialized (data is all zeros or discriminator doesn't match).

**Fix:**
```typescript
// Check if account needs initialization
const accountInfo = await connection.getAccountInfo(pda);
const needsInit = !accountInfo || accountInfo.data.length === 0
  || accountInfo.data.slice(0, 8).every(b => b === 0);

if (needsInit) {
  // Call the init instruction first
  await program.methods.initialize()
    .accounts({
      pda,
      authority: wallet.publicKey,
      systemProgram: SystemProgram.programId,
    })
    .rpc();
}
```

---

## 8. SPL InsufficientFunds

**Log:**
```
Program TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA failed: custom program error: 0x1
```

**Cause:** Token account doesn't have enough balance for the transfer.

**Fix:**
```typescript
// Check balance before transferring
const tokenAccount = await getAccount(connection, tokenAccountAddress);
const balance = tokenAccount.amount;

if (balance < transferAmount) {
  throw new Error(`Insufficient: have ${balance}, need ${transferAmount}`);
}

// For raw SPL: check the account data directly
const accountInfo = await connection.getAccountInfo(tokenAccountAddress);
// Token account layout: amount is at offset 64, 8 bytes little-endian
const amount = accountInfo.data.readBigUInt64LE(64);
```

---

## 9. SPL OwnerMismatch

**Log:**
```
Program TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA failed: custom program error: 0x3
```

**Cause:** The signer is not the owner/delegate of the token account.

**Fix:**
```typescript
// Verify owner before transfer
const tokenAccount = await getAccount(connection, sourceAccount);
if (!tokenAccount.owner.equals(wallet.publicKey)) {
  // Check if wallet is a delegate
  if (!tokenAccount.delegate?.equals(wallet.publicKey)) {
    throw new Error("Wallet is neither owner nor delegate");
  }
  // If delegate, check delegated amount
  if (tokenAccount.delegatedAmount < transferAmount) {
    throw new Error("Delegated amount insufficient");
  }
}
```

---

## 10. SPL NotInitialized

**Log:**
```
Program TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA failed: custom program error: 0x6
```

**Cause:** Token account hasn't been initialized yet.

**Fix:**
```typescript
import { createAssociatedTokenAccountInstruction } from "@solana/spl-token";

// Create and initialize an ATA in the same transaction
const ata = getAssociatedTokenAddressSync(mint, owner);
const ataIx = createAssociatedTokenAccountInstruction(
  payer,
  ata,
  owner,
  mint,
);

const tx = new Transaction().add(ataIx, transferIx);
```

---

## 11. Token-2022 Transfer Fee

**Log:**
```
Program TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb failed: custom program error: 0x1
```

**Cause:** Token-2022 mint has a transfer fee extension. The fee is deducted from the sent amount, so the source account needs `amount + fee` tokens.

**Fix:**
```typescript
import { getTransferFeeAmount, getMint } from "@solana/spl-token-2022";

const mintInfo = await getMint(connection, mint, undefined, TOKEN_2022_PROGRAM_ID);
const transferFeeConfig = mintInfo.transferFeeConfig;

if (transferFeeConfig) {
  const feeBps = transferFeeConfig.transferFeeBasisPoints;
  const fee = (amount * BigInt(feeBps)) / 10000n;
  const totalNeeded = amount + fee;

  // Check source has enough
  const sourceAccount = await getAccount(connection, source, undefined, TOKEN_2022_PROGRAM_ID);
  if (sourceAccount.amount < totalNeeded) {
    throw new Error(`Need ${totalNeeded} (amount + fee), have ${sourceAccount.amount}`);
  }
}

// Use transferCheckedWithFee for Token-2022 transfers with fees
import { transferCheckedWithFee } from "@solana/spl-token-2022";
```

---

## 12. AccountFrozen

**Log:**
```
Program TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb failed: custom program error: 0x16
```

**Cause:** The token account has been frozen by the mint's freeze authority.

**Fix:**
```typescript
// Check if account is frozen
const account = await getAccount(connection, tokenAccount, undefined, TOKEN_2022_PROGRAM_ID);
if (account.isFrozen) {
  // Only the freeze authority can unfreeze
  // Contact the mint authority, or:
  import { thawAccount } from "@solana/spl-token-2022";
  await thawAccount(
    connection,
    freezeAuthority, // must be signer
    tokenAccount,
    mint,
    [],
    undefined,
    TOKEN_2022_PROGRAM_ID,
  );
}
```

---

## 13. NegativeLamports

**Log:**
```
Program 11111111111111111111111111111111 failed: custom program error: 0x1
```

**Cause:** A `SystemProgram.transfer` would leave the source account with negative lamports (insufficient SOL).

**Fix:**
```typescript
const balance = await connection.getBalance(source);
if (balance < transferAmount) {
  // Fund the account first, or reduce the transfer amount
  const fundIx = SystemProgram.transfer({
    fromPubkey: payer,
    toPubkey: source,
    lamports: transferAmount - balance,
  });
  const tx = new Transaction().add(fundIx, transferIx);
}
```

---

## 14. UnbalancedInstruction

**Log:**
```
Program 11111111111111111111111111111111 failed: custom program error: 0x7
```

**Cause:** Total lamports in ≠ total lamports out for a System program instruction. This is a hard constraint — SOL can't be created or destroyed.

**Fix:** Ensure the sum of all input lamports equals the sum of all output lamports:

```typescript
// Wrong — 1 SOL in, 2 SOL out
const ix = SystemProgram.transfer({
  fromPubkey: source,    // has 1 SOL
  toPubkey: destination,
  lamports: 2_000_000_000, // 2 SOL — more than source has
});

// Fixed — transfer only what's available
const balance = await connection.getBalance(source);
const ix = SystemProgram.transfer({
  fromPubkey: source,
  toPubkey: destination,
  lamports: balance - 5000, // leave enough for fee
});
```

---

## 15. InstructionFellThrough

**Log:**
```
Program log: Instruction fell through
Program <id> failed: custom program error: 0x0
```

**Cause:** The BPF program didn't match any instruction variant. The instruction discriminator (first 8 bytes of data) doesn't match any known instruction.

**Fix:**
```typescript
// Anchor instruction discriminator = sha256("global:<instruction_name>")[0..8]
// Verify you're calling the right instruction

// If using Anchor client:
await program.methods.myInstruction(arg1, arg2)
  .accounts({...})
  .rpc();

// If building raw instruction:
const discriminator = Buffer.from(
  createHash('sha256').update('global:myInstruction').digest()
).slice(0, 8);

const ix = new TransactionInstruction({
  programId,
  keys: [...],
  data: Buffer.concat([discriminator, /* encoded args */]),
});
```

**Common cause:** Wrong program ID, or the program was updated and instruction names changed.

---

## 16. TxTooLarge

**Error:**
```
Transaction too large: N bytes (max 1232)
```

**Cause:** Serialized transaction exceeds 1,232 bytes.

**Fix:**
```typescript
// 1. Use an Address Lookup Table to compress account references
import { AddressLookupTableProgram, TransactionMessage, VersionedTransaction } from "@solana/web3.js";

// Create ALT and add addresses
const [createIx, altAddress] = AddressLookupTableProgram.createLookupTable({
  authority: payer,
  payer,
  slot: await connection.getSlot(),
});
await sendAndConfirmTransaction(connection, new Transaction().add(createIx), [payer]);

const extendIx = AddressLookupTableProgram.extendLookupTable({
  lookupTable: altAddress,
  authority: payer,
  payer,
  addresses: allAccountAddresses,
});
await sendAndConfirmTransaction(connection, new Transaction().add(extendIx), [payer]);

// Wait 1 slot, then build versioned tx
const altAccount = (await connection.getAddressLookupTable(altAddress)).value;
const message = TransactionMessage.compileToV0Message(
  instructions,
  payer,
  [altAccount],
);
const tx = new VersionedTransaction(message);
```

**Also:** Reduce signers (each = 64 bytes), shorten instruction data, remove unnecessary accounts.

---

## 17. VersionNotSupported

**Error:**
```json
{"code": -32602, "message": "Transaction version (0) is not supported"}
```

**Cause:** Fetching a versioned transaction without `maxSupportedTransactionVersion: true`.

**Fix:**
```typescript
// Add maxSupportedTransactionVersion to ALL getTransaction calls
const tx = await connection.getTransaction(signature, {
  maxSupportedTransactionVersion: true,
});
```

---

## 18. ATA AlreadyInitialized

**Log:**
```
Program ATokenGPvbdGVxr1b2hvZbsiqW5xWH25efTNsLJA8knL failed: custom program error: 0x0
```

**Cause:** The associated token account already exists. Calling `createAssociatedTokenAccount` on an existing ATA fails.

**Fix:**
```typescript
import { getAssociatedTokenAddressSync, createAssociatedTokenAccountIdempotentInstruction } from "@solana/spl-token";

// Use the idempotent version — it succeeds even if ATA already exists
const ata = getAssociatedTokenAddressSync(mint, owner);
const ix = createAssociatedTokenAccountIdempotentInstruction(
  payer,
  ata,
  owner,
  mint,
);
// This won't fail if the ATA already exists
```

---

## 19. TxNotLanding

**Symptom:** Transaction is submitted but never confirmed (no error, just pending forever).

**Cause:** Priority fee too low for network congestion, or transaction dropped by leader.

**Fix:**
```typescript
// 1. Estimate and set a competitive priority fee
const priorityFees = await connection.getRecentPrioritizationFees();
const medianFee = priorityFees
  .map(f => f.prioritizationFee)
  .sort((a, b) => a - b)[Math.floor(priorityFees.length / 2)];

const tx = new Transaction().add(
  ComputeBudgetProgram.setComputeUnitLimit({ units: 200_000 }),
  ComputeBudgetProgram.setComputeUnitPrice({ microLamports: medianFee * 2 }), // 2x median
  // ... your instructions
);

// 2. Use a reliable submission method with retries
const { blockhash, lastValidBlockHeight } = await connection.getLatestBlockhash();
tx.recentBlockhash = blockhash;

const sig = await connection.sendRawTransaction(tx.serialize(), {
  skipPreflight: false,
  preflightCommitment: "confirmed",
  maxRetries: 5,
});

// 3. Confirm with block height timeout
await connection.confirmTransaction({
  signature: sig,
  blockhash,
  lastValidBlockHeight,
}, "confirmed");
```

**Also:** Consider using a transaction service like Helius Smart WebSockets or Jito for MEV protection.

---

## 20. CPIDepth

**Log:**
```
Program <id> failed: MaxInstructionTraceLengthExceeded
```
or
```
Program <id> failed: too many calls to solana_log_
```

**Cause:** CPI depth exceeded 4 levels (A→B→C→D→E is the max).

**Fix:** Flatten your program architecture:
- Move logic from callee programs into the caller
- Use a single program with multiple instructions instead of nested CPIs
- Pre-compute results off-chain and pass them as instruction data

---

## 21. AccountInUse

**Log:**
```
TransactionError: AccountInUse
```

**Cause:** Another transaction is currently being processed that locks one of the same accounts. This is transient.

**Fix:**
```typescript
// Retry with backoff
async function sendWithRetry(connection, tx, signers, maxRetries = 5) {
  for (let i = 0; i < maxRetries; i++) {
    try {
      const sig = await sendAndConfirmTransaction(connection, tx, signers);
      return sig;
    } catch (e) {
      if (e.message.includes("AccountInUse") && i < maxRetries - 1) {
        await new Promise(r => setTimeout(r, 500 * (i + 1)));
        // Refresh blockhash
        const { blockhash } = await connection.getLatestBlockhash();
        tx.recentBlockhash = blockhash;
        continue;
      }
      throw e;
    }
  }
}
```

---

## 22. UnknownCustom

**Log:**
```
Program <id> failed: custom program error: 0x<code>
```

**Cause:** Custom error from a program that isn't Anchor, SPL, System, or Token-2022.

**Fix:**
1. Identify the program ID from the logs
2. Look up the program's source code or IDL on [Solana Explorer](https://explorer.solana.com)
3. Find the `#[error_code]` enum (for Anchor) or error constants
4. Map the code: for Anchor, `index = hex_code - 0x1000`
5. If no source available, check the program's documentation or GitHub

```typescript
// Generic decoder
function decodeCustomError(hexCode: string, programId: string): string {
  const code = parseInt(hexCode, 16);

  // Check if it's an Anchor error (0x1000+)
  if (code >= 0x1000) {
    const anchorIndex = code - 0x1000;
    if (anchorIndex < 256) {
      return `Anchor built-in error #${anchorIndex}`;
    }
    return `Custom Anchor error #${anchorIndex - 256} (check program's #[error_code])`;
  }

  // Check known programs
  const programMap: Record<string, string> = {
    "TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA": "SPL Token",
    "TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb": "Token-2022",
    "11111111111111111111111111111111": "System",
  };

  const programName = programMap[programId] ?? "Unknown program";
  return `${programName} error: 0x${hexCode} (decimal: ${code})`;
}
```
