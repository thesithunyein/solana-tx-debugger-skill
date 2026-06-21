# Compute Budget: CU Limits, Priority Fees & Fixes

> Diagnose and fix `ComputationalBudgetExceeded` and compute-related transaction failures.

## The Default Limit

Every Solana transaction has a **default compute unit limit of 200,000 CU**. This is per-transaction, not per-instruction. If your transaction uses multiple instructions, they share this budget.

## Checking Compute Usage

### From a Confirmed Transaction

```typescript
const tx = await connection.getTransaction(signature, {
  maxSupportedTransactionVersion: true,
});
const cuUsed = tx?.meta?.computeUnitsConsumed;
// Compare against the limit set in the transaction
```

### From Simulation

```typescript
const simulation = await connection.simulateTransaction(transaction, {
  replaceRecentBlockhash: true,
  sigVerify: false,
});
const cuUsed = simulation.value?.unitsConsumed;
const logs = simulation.value?.logs;
```

## Setting Compute Unit Limit

```typescript
import { ComputeBudgetProgram } from "@solana/web3.js";

const instructions = [
  ComputeBudgetProgram.setComputeUnitLimit({ units: 400_000 }),
  ComputeBudgetProgram.setComputeUnitPrice({ microLamports: 1_000 }), // priority fee
  // ... your actual instructions
];
```

### In Anchor

```rust
use anchor_lang::solana_program::compute_budget;

#[derive(Accounts)]
pub struct MyInstruction<'info> {
    // ...
}

pub fn handler(ctx: Context<MyInstruction>) -> Result<()> {
    compute_budget::set_compute_unit_limit(400_000);
    compute_budget::set_compute_unit_price(1_000);
    // ...
    Ok(())
}
```

Or via `invoke()` in the instruction builder:

```rust
let compute_budget_ix = ComputeBudgetInstruction::set_compute_unit_limit(400_000);
let priority_fee_ix = ComputeBudgetInstruction::set_compute_unit_price(1_000);
```

## Common Compute Budget Errors

### `ComputationalBudgetExceeded`

**Log pattern:**
```
Program ComputeBudget111111111111111111111111111111 failed: ComputationalBudgetExceeded
```

**Cause:** Transaction consumed more CU than the limit (default 200,000 or whatever was set).

**Fix:**
1. **Raise the limit** — add `ComputeBudgetProgram.setComputeUnitLimit({ units: N })` where N is high enough (max 1,400,000 per tx).
2. **Optimize the program** — reduce CU usage:
   - Avoid unnecessary account loads
   - Use `zero_copy` for large accounts in Anchor
   - Minimize `Vec` iterations
   - Use `#[inline(always)]` for hot paths
   - Avoid `format!()` and string operations in on-chain code
3. **Split the transaction** — if a single tx does too much, split into multiple transactions.

### `InsufficientFundsForPriorityFee`

**Cause:** The account doesn't have enough SOL to pay the priority fee on top of the base fee.

**Fix:** Ensure the fee payer has enough SOL for: `base_fee + priority_fee + rent` for any new accounts.

## Priority Fee Best Practices

### How Priority Fees Work

- **Base fee:** 5,000 lamports per signature (flat)
- **Priority fee:** `compute_unit_price * (compute_units_used / 1_000_000)` lamports
- Higher `compute_unit_price` = higher priority in the leader's queue

### Estimating Priority Fees

```typescript
// Get recent priority fee estimates
const priorityFees = await connection.getRecentPrioritizationFees({
  lockedWritableAccounts: [programId],
});
// Returns array of { slot, prioritizationFee } for recent slots

const medianFee = priorityFees
  .map(f => f.prioritizationFee)
  .sort((a, b) => a - b)[Math.floor(priorityFees.length / 2)];
```

### Using Helius Priority Fee API

```typescript
const response = await fetch(`https://mainnet.helius-rpc.com/?api-key=${HELIUS_KEY}`, {
  method: "POST",
  headers: { "Content-Type": "application/json" },
  body: JSON.stringify({
    jsonrpc: "2.0",
    id: "1",
    method: "getPriorityFeeEstimate",
    params: [{
      transaction: serializedTxBase64,
      options: { priorityLevel: "high" },
    }],
  }),
});
const { priorityFeeEstimate } = (await response.json()).result;
```

## Compute Unit Optimization Tips

| Optimization | CU Saved (approx) |
|---|---|
| Use `#[account(zero_copy)]` instead of `Box<Account>` for large accounts | 30-50% on account load |
| Avoid `Vec<u8>` copies — use slices | varies |
| Replace `format!()` with static strings | ~1,000 CU per call |
| Use `#[inline(always)]` on hot functions | varies |
| Reduce number of accounts passed | ~300 CU per account |
| Use `remaining_accounts` sparingly | ~300 CU per account |
| Pre-compute PDAs off-chain, pass as accounts | ~1,500 CU per PDA |
| Use `InstructionName` instead of `InstructionName + data` when possible | ~100 CU |

## Max Compute Unit Limit

The hard maximum is **1,400,000 CU per transaction** (as of 2026). Setting `setComputeUnitLimit` above this has no effect.

## Compute Budget Instruction Order

Compute budget instructions must be included in the transaction **before** the instructions they affect. Place them first:

```typescript
const tx = new Transaction().add(
  ComputeBudgetProgram.setComputeUnitLimit({ units: 400_000 }),
  ComputeBudgetProgram.setComputeUnitPrice({ microLamports: 5_000 }),
  // your instructions here
);
```
