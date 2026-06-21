# /debug-tx Command

> Usage: `/debug-tx <signature> [network]`

## Description

Diagnoses a failed Solana transaction by signature. Fetches the transaction, extracts the error, classifies it, identifies the root cause, and prescribes a fix.

## Arguments

- `signature` (required) — The transaction signature to debug
- `network` (optional) — `mainnet` (default), `devnet`, or `testnet`

## Workflow

1. **Fetch the transaction**
   - Use `getTransaction(signature, { maxSupportedTransactionVersion: 0, commitment: "confirmed" })`
   - If not found, check `getSignatureStatuses` — may be unconfirmed or expired
   - If on devnet/testnet, use the appropriate RPC endpoint

2. **Extract error data**
   - Parse `meta.err` for the error type and code
   - Read `meta.logMessages` bottom-up for the failing program
   - Note `meta.computeUnitsConsumed` and compare against limit
   - Check `meta.innerInstructions` for CPI failures

3. **Classify the error**
   - Load [`skill/error-codes.md`](../skill/error-codes.md)
   - Match the error code against known maps
   - Identify the program framework (Anchor / SPL / Token-2022 / System / custom)

4. **Find the root cause**
   - Check [`skill/recipes.md`](../skill/recipes.md) for a direct match
   - If no match, analyze logs + context using the relevant sub-skill:
     - Compute issues → [`skill/compute-budget.md`](../skill/compute-budget.md)
     - Account/CPI issues → [`skill/cpi-and-accounts.md`](../skill/cpi-and-accounts.md)
     - ALT/size issues → [`skill/alt-and-size.md`](../skill/alt-and-size.md)
     - Simulation issues → [`skill/simulation.md`](../skill/simulation.md)

5. **Output the diagnosis**
   - Use the format defined in [`agents/tx-debugger.md`](../agents/tx-debugger.md)
   - Include: error, root cause, evidence from logs, fix with code snippet, prevention tip

## Example Usage

```
/debug-tx 5Kj8n2Wp...signature...mainnet

/debug-tx 5Kj8n2Wp...signature... devnet
```

## Example Output

```
## Transaction Diagnosis

**Signature:** 5Kj8n2Wp...
**Network:** mainnet
**Status:** failed

### Error
Anchor error 3010 (0xBC2) — AccountNotSigner

### Root Cause
The account at index 2 was not passed as a signer in the transaction.

### Evidence
- Log: "AnchorError ... Error Code: AccountNotSigner. Error Number: 3010" / "custom program error: 0xbc2"
- Account at index 2 (9xY...) is marked Signer in the Anchor accounts struct
- Transaction signers: [3xY...] — 9xY... is not in the signer list

### Fix
Add the missing account as a signer:
\`\`\`typescript
await program.methods.myInstruction()
  .accounts({ authority: wallet.publicKey })
  .signers([wallet]) // ensure wallet signs
  .rpc();
\`\`\`

### Prevention
Always verify signer requirements match your Anchor `#[derive(Accounts)]` struct before sending.
```

## Notes

- This command is read-only — it only fetches transaction data, never sends transactions.
- For versioned transactions, `maxSupportedTransactionVersion: 0` is always set.
- If the transaction succeeded (meta.err is null), report that and show compute usage.
- If the transaction is not found, suggest checking the network or waiting for confirmation.
