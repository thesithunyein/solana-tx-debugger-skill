# CPI & Account Errors

> Diagnose and fix Cross-Program Invocation (CPI) errors, account mismatches, and PDA errors.

## CPI Depth Limit

Solana allows a maximum CPI depth of **4** (i.e., A→B→C→D→E). If you exceed this:

```
Program log: Instruction fell through
Program <id> failed: ComputationalBudgetExceeded
```

Actually, exceeding CPI depth gives:
```
Program <id> failed: too many calls to solana_log_
```
or more commonly:
```
Program <id> failed: MaxInstructionTraceLengthExceeded
```

**Fix:** Restructure your program to reduce call depth. Flatten nested CPIs or use a single instruction that does more work.

## Common Account Errors

### `AccountNotFound`

**Log pattern:**
```
Program log: Account not found
Program <id> failed: InstructionError { index: 0, error: AccountNotFound }
```

**Cause:** An account required by the instruction was not passed in the transaction's account list.

**Fix:** Ensure all required accounts are passed. In Anchor, check your `#[derive(Accounts)]` struct — every field must have a corresponding account in the instruction call.

```typescript
// Missing account — will fail
await program.methods.myInstruction()
  .accounts({ authority: wallet.publicKey })
  .rpc();

// Fixed — pass all required accounts
await program.methods.myInstruction()
  .accounts({
    authority: wallet.publicKey,
    dataAccount: pda,
    systemProgram: SystemProgram.programId,
  })
  .rpc();
```

### `AccountNotSigner` (Anchor 0x1006)

**Cause:** An account marked with `Signer` in the `#[derive(Accounts)]` struct was not passed as a signer.

**Fix:**
```typescript
// Wrong — account not signed
await program.methods.myInstruction()
  .accounts({ authority: someAccount })
  .rpc();

// Fixed — sign with the account
await program.methods.myInstruction()
  .accounts({ authority: wallet.publicKey })
  .signers([wallet]) // or use wallet as fee payer
  .rpc();
```

In Anchor:
```rust
#[derive(Accounts)]
pub struct MyInstruction<'info> {
    #[account(mut, signer)]
    pub authority: Signer<'info>, // This MUST be a signer
}
```

### `AccountNotWritable` (Anchor 0x1007)

**Cause:** An account marked `mut` in the Accounts struct was passed as read-only.

**Fix:** Mark the account as writable in the transaction:

```typescript
// Wrong — account is read-only
await program.methods.myInstruction()
  .accounts({ dataAccount: someAccount })
  .remainingAccounts([{ pubkey: someAccount, isSigner: false, isWritable: false }])
  .rpc();

// Fixed — mark as writable
await program.methods.myInstruction()
  .accounts({ dataAccount: someAccount })
  .remainingAccounts([{ pubkey: someAccount, isSigner: false, isWritable: true }])
  .rpc();
```

### `IncorrectProgramId` (Anchor 0x1005)

**Cause:** An account is owned by a different program than expected.

**Fix:** Verify account ownership before passing. In Anchor, use `Account<'info, MyType>` which checks ownership automatically. If using `AccountInfo`, check manually:

```rust
if account.owner != expected_program_id {
    return Err(ErrorCode::IncorrectProgramId.into());
}
```

### `ConstraintSeeds` / PDA Mismatch (Anchor 0x100e)

**Log pattern:**
```
Program log: AnchorError: Error: ConstraintSeeds
```

**Cause:** The PDA derived from the seeds doesn't match the account passed.

**Fix:** Verify your seeds match exactly:

```typescript
// Wrong — wrong seeds
const [pda] = PublicKey.findProgramAddressSync(
  [Buffer.from("wrong_seed")],
  programId
);

// Fixed — correct seeds
const [pda] = PublicKey.findProgramAddressSync(
  [Buffer.from("correct_seed"), wallet.publicKey.toBuffer()],
  programId
);
```

Common seed mistakes:
- Using `utf8.encode("seed")` vs `Buffer.from("seed")` — they're the same, but watch for trailing nulls
- Forgetting to include the bump seed in the account but not in the derivation
- Using a different encoding (e.g., `bs58` vs raw bytes)

### `AccountDiscriminatorMismatch` (Anchor 0x1013)

**Cause:** The account's 8-byte discriminator doesn't match the expected Anchor account type.

**Fix:** You're passing the wrong account type. Each Anchor account type has a unique discriminator (first 8 bytes of `sha256("account:<AccountName>")`).

```typescript
// Check the discriminator
const expectedDiscriminator = Buffer.from(
  sha256("account:MyData").slice(0, 8),
  "hex"
);
const accountData = await connection.getAccountInfo(pda);
const actualDiscriminator = accountData?.data.slice(0, 8);

if (!expectedDiscriminator.equals(actualDiscriminator)) {
  console.log("Wrong account type — expected MyData, got something else");
}
```

### `UninitializedAccount` (Anchor 0x100b)

**Cause:** The account exists but hasn't been initialized (discriminator is all zeros or doesn't match).

**Fix:** Call the `initialize` instruction first, or check if the account needs to be created:

```typescript
const accountInfo = await connection.getAccountInfo(pda);
if (!accountInfo || accountInfo.data.length === 0) {
  // Account doesn't exist — need to create/initialize it
  await program.methods.initialize()
    .accounts({ pda, authority: wallet.publicKey, systemProgram: SystemProgram.programId })
    .rpc();
}
```

## CPI-Specific Errors

### `Instruction fell through`

**Log pattern:**
```
Program log: Instruction fell through
Program <id> failed: custom program error: 0x0
```

**Cause:** The BPF program reached the end of the instruction function without returning. This usually means the instruction dispatcher didn't match any known instruction variant.

**Fix:** Check the instruction discriminator (first 8 bytes of instruction data). In Anchor, this is `sha256("global:<instruction_name>")[0..8]`.

### CPI to Wrong Program

**Symptom:** The CPI call succeeds but modifies the wrong account, or fails with `IncorrectProgramId`.

**Fix:** Always verify the program ID in your CPI:

```rust
// In Anchor
let cpi_program = ctx.accounts.target_program.to_account_info();
let cpi_accounts = TargetAccounts {
    authority: ctx.accounts.authority.to_account_info(),
    // ...
};
let cpi_ctx = CpiContext::new(cpi_program, cpi_accounts);
anchor_program::cpi::target_instruction(cpi_ctx, data)?;
```

### `InsufficientFundsForRent` (Anchor 0x1016)

**Cause:** After the operation, the account's lamport balance is below the rent-exempt minimum.

**Fix:** Ensure the account has enough SOL. Rent-exempt minimum for an account of size N bytes:

```typescript
const rentExempt = await connection.getMinimumBalanceForRentExemption(size);
// Ensure account has at least this many lamports
```

## Debugging CPI Failures

### Reading Inner Instructions

CPI calls appear as "inner instructions" in the transaction metadata:

```typescript
const innerInstructions = tx.meta?.innerInstructions ?? [];
for (const inner of innerInstructions) {
  console.log(`Outer instruction #${inner.index}:`);
  for (const ix of inner.instructions) {
    const programId = accountKeys.get(ix.programIdIndex);
    console.log(`  → CPI to ${programId}`);
  }
}
```

### Tracing the Failing CPI

1. Find the last `Program <id> failed` in logs
2. Check if that program ID is a CPI callee (appears in inner instructions)
3. The error code from that program is the root cause
4. Map the error code using [`error-codes.md`](error-codes.md)

## Account Validation Checklist

- [ ] All required accounts are passed (no `AccountNotFound`)
- [ ] Signer accounts are actually signing (no `AccountNotSigner`)
- [ ] Writable accounts are marked `isWritable: true` (no `AccountNotWritable`)
- [ ] Account ownership matches expected program (no `IncorrectProgramId`)
- [ ] PDA seeds match derivation (no `ConstraintSeeds`)
- [ ] Account discriminator matches type (no `AccountDiscriminatorMismatch`)
- [ ] Account is initialized (no `UninitializedAccount`)
- [ ] Account has enough lamports for rent (no `InsufficientFundsForRent`)
- [ ] CPI depth ≤ 4
