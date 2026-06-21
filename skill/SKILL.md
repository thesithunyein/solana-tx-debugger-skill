# Solana TX Debugger Skill

> Entry point for Solana transaction debugging. Routes to focused sub-skills — load only what you need.

## When to Use This Skill

Use this skill when a developer needs to:
- Debug a **failed Solana transaction** (by signature or simulation)
- Understand a **cryptic program error** (hex code, Anchor error, SPL error)
- Fix a **compute budget exceeded** error
- Resolve **CPI / account mismatch** errors
- Troubleshoot **address lookup table** or **transaction size** issues
- **Simulate** a transaction before sending to understand why it would fail

## Quick Routing

| Problem | Load this file |
|---|---|
| Need to fetch tx data / read logs / extract errors | [`triage.md`](triage.md) |
| Got a hex error code or Anchor error number | [`error-codes.md`](error-codes.md) |
| `ComputationalBudgetExceeded` or CU optimization | [`compute-budget.md`](compute-budget.md) |
| CPI error, account not found, PDA mismatch, signer issues | [`cpi-and-accounts.md`](cpi-and-accounts.md) |
| ALT errors, tx too large, versioned tx issues | [`alt-and-size.md`](alt-and-size.md) |
| Want to simulate a tx before sending | [`simulation.md`](simulation.md) |
| Want a direct error → cause → fix lookup | [`recipes.md`](recipes.md) |
| Need RPC endpoints, explorers, reference links | [`resources.md`](resources.md) |

## Debugging Workflow

1. **Triage** → [`triage.md`](triage.md): Fetch the transaction (or simulate it). Extract: program ID, logs, error code, compute units used, account list.
2. **Classify** → [`error-codes.md`](error-codes.md): Match the error code against known maps (Anchor, SPL, Token-2022, System).
3. **Diagnose** → Use the matched error + logs + context to identify root cause. Check [`recipes.md`](recipes.md) for a direct match.
4. **Prescribe** → Provide a concrete fix with a code snippet. If the error is compute-related, see [`compute-budget.md`](compute-budget.md). If CPI/account-related, see [`cpi-and-accounts.md`](cpi-and-accounts.md). If ALT/size-related, see [`alt-and-size.md`](alt-and-size.md).

## Key Facts (Quick Reference)

- Default compute budget: **200,000 CU per instruction**, capped at **1,400,000 CU per transaction** (set explicitly via `ComputeBudgetProgram.setComputeUnitLimit`, max 1.4M)
- Max transaction size: **1,232 bytes** (legacy) / **1,232 bytes** with ALTs (versioned)
- Max CPI depth: **4** (inner instructions)
- Anchor error format: `custom program error: 0x<code>` where the code is a plain number (no offset). Framework errors are in fixed ranges (2000s = constraint, 3000s = account); **user-defined `#[error_code]` errors start at 6000 (0x1770)**, so `index = decimal - 6000`
- Token-2022 program ID: `TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb`
- SPL Token program ID: `TokenkegQfeZyiNwAJbNbGKPFXCWuBvf9Ss623VQ5DA`
- System program ID: `11111111111111111111111111111111`

## Important Notes

- **Always fetch the full transaction** with `getTransaction` (not just `getSignatureStatuses`) — logs and inner instructions are critical.
- **Use `maxSupportedTransactionVersion: 0`** when fetching versioned transactions, or you'll get an error.
- **Read logs bottom-up** — the last program log line usually contains the actual error.
- **Check inner instructions** for CPI failures — the failing program may be a callee, not the top-level instruction.
