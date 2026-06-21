# Solana TX Debugger Skill for Claude Code

> Paste a failing transaction signature → get a human-readable diagnosis and suggested fix.

![Solana TX Debugger demo](demo.gif)

A [Solana AI Kit](https://github.com/solanabr/solana-ai-kit) skill that turns any coding agent into an expert Solana transaction debugger. It covers the full 2026 stack: Anchor, Token-2022, versioned transactions, address lookup tables, compute budget, CPI, and more.

**🔗 Live demo:** [solana-explainer.vercel.app](https://solana-explainer.vercel.app) — paste a signature (or click *See an example diagnosis*) to watch the skill's logic run in the browser.

> **Why this exists:** the same error-decoding engine that powers the live demo is distilled into the markdown skill files, so your agent diagnoses failures with the same accuracy — directly in your editor.

## The Problem

Every Solana developer hits cryptic failed-transaction errors:

```
Program logged: "Instruction fell through"
Program returned error: "custom program error: 0x1"
Transaction simulation failed: BlockHashNotFound
```

These errors are scattered across program logs, Anchor error codes, SPL error codes, and raw hex — with no single source that maps them to a **cause** and a **fix**. Developers waste hours grepping logs, reading source code, and guessing.

## What This Skill Does

The TX Debugger Skill gives your AI agent a structured debugging workflow:

1. **Triage** — fetch the transaction (or simulate it), extract logs, meta, and error codes
2. **Classify** — match the error against known Anchor/SPL/System/Token-2022 error-code maps
3. **Diagnose** — identify root cause from program logs, CPI depth, compute usage, and account state
4. **Prescribe** — provide a concrete fix with runnable code snippets

## How This Is Different

Most "transaction" tooling in the ecosystem focuses on **landing** transactions — retries, priority fees, and RPC reliability. This skill focuses on the opposite, harder problem: **a transaction already failed, now explain *why* and *how to fix it*.**

- **Decodes, not just detects** — maps raw codes (`0x7d6`, `custom program error: 0xbc2`) to the exact framework error (`ConstraintSeeds`, `AccountNotSigner`) using the *real* Anchor/SPL/System/Token-2022 enums — including the fact that user-defined Anchor errors start at **6000**, not the commonly-mistaken `0x1000` offset.
- **Prescribes a fix** — every recipe ships a runnable code snippet and a prevention tip, not just a definition.
- **Cross-framework** — Anchor, SPL Token, Token-2022 extensions, System, ALTs/versioned txs, compute budget, and CPI depth in one place.
- **Verifiable** — the same decoding engine runs in the [live demo](https://solana-explainer.vercel.app), so you can confirm accuracy before you trust it.

## Installation

### Standard Install

```bash
git clone https://github.com/thesithunyein/solana-tx-debugger-skill.git
cd solana-tx-debugger-skill
chmod +x install.sh
./install.sh
```

### Custom Install

```bash
./install-custom.sh --target ~/.codex/skills/solana-tx-debugger-skill --with-rules
```

Options:
- `--target <path>` — custom install directory
- `--no-agents` — skip agent persona
- `--no-commands` — skip `/debug-tx` command
- `--with-rules` — include code rules

### If You Already Have solana-dev-skill

This skill is an **addon**, not a replacement. It installs side-by-side with `solana-dev-skill` and any other kit skills you have. No conflicts.

## Usage Examples

### Example 1: Debug a failed Anchor instruction

```
/debug-tx 5Kj8...signature...

# Agent output:
# → Fetched transaction from mainnet
# → Program: anchor_program (BPF)
# → Error: custom program error: 0xbc2
# → Match: Anchor Error 3010 (0xBC2) — "AccountNotSigner"
# → Cause: The account at index 2 was not passed as a signer
# → Fix: Add .signer(account) to your Anchor accounts struct
```

### Example 2: Compute budget exceeded

```
/debug-tx 3xY9...signature...

# Agent output:
# → Error: ComputationalBudgetExceeded
# → Compute units used: 201,543 / 200,000
# → Cause: Instruction exceeds default CU limit
# → Fix: Add ComputeBudgetProgram.setComputeUnitLimit(400_000)
#        and setComputeUnitPrice(priority_fee) to your tx
```

### Example 3: Token-2022 transfer fee failure

```
/debug-tx 7mK2...signature...

# Agent output:
# → Program: Token-2022 (TokenzQdBNbLqP5VEhdkAS6EPFLC1PHnBqCXEpPxuEb)
# → Error: 0x24 (InsufficientFunds)
# → Cause: Transfer fee extension deducted more than expected
# → Fix: Account for transfer fee in amount calculation:
#        let fee = (amount * fee_bps) / 10000;
#        let needed = amount + fee;
```

## What's Included

### Skills (`skill/`)
- **SKILL.md** — entry point with progressive routing
- **triage.md** — fetching tx data, reading meta, extracting errors
- **error-codes.md** — Anchor, SPL, Token-2022, System program error-code maps
- **compute-budget.md** — CU limits, priority fees, exceeded-CU fixes
- **cpi-and-accounts.md** — CPI depth, account mismatches, PDA errors
- **alt-and-size.md** — address lookup tables, tx size limits, versioned tx pitfalls
- **simulation.md** — simulateTransaction workflow, log interpretation
- **recipes.md** — 20+ real error → cause → fix recipes (the core value)
- **resources.md** — RPC endpoints, explorers, reference links

### Agents (`agents/`)
- **tx-debugger.md** — agent persona that runs the full debugging workflow

### Commands (`commands/`)
- **debug-tx.md** — `/debug-tx <signature>` workflow command

## Demo

A live demo is available at: **[solana-explainer.vercel.app](https://solana-explainer.vercel.app)** — repo: [thesithunyein/solana-tx-explainer](https://github.com/thesithunyein/solana-tx-explainer)

Paste any Solana transaction signature and get an instant human-readable diagnosis.

## Repository Structure

```
solana-tx-debugger-skill/
├── CLAUDE.md              # Claude configuration
├── README.md              # This file
├── LICENSE                # MIT
├── install.sh             # Standard installer
├── install-custom.sh      # Custom installer with options
├── skill/
│   ├── SKILL.md           # Entry point (progressive routing)
│   ├── triage.md          # Fetching & reading tx data
│   ├── error-codes.md     # Error-code maps (Anchor/SPL/Token-2022/System)
│   ├── compute-budget.md  # CU limits, priority fees
│   ├── cpi-and-accounts.md # CPI, account mismatches, PDAs
│   ├── alt-and-size.md    # ALTs, tx size, versioned txs
│   ├── simulation.md      # simulateTransaction workflow
│   ├── recipes.md         # 20+ error → cause → fix recipes
│   └── resources.md       # RPC refs, explorers, links
├── agents/
│   └── tx-debugger.md     # Debugging agent persona
└── commands/
    └── debug-tx.md        # /debug-tx command
```

## Design Principles

- **Progressive / token-efficient** — `SKILL.md` stays small and routes to focused sub-files loaded only when needed
- **Accuracy-first** — every error code and fix is verified against real on-chain behavior
- **Current to the 2026 stack** — Token-2022 extensions, versioned transactions, ALTs, compute budget
- **Safe & lean** — no opaque executables, no bloat, minimal dependencies, MIT licensed

## Contributing

PRs welcome. Please verify any new error recipes against real transactions before submitting.

## License

MIT — see [LICENSE](LICENSE)

## Related

- [Solana AI Kit](https://github.com/solanabr/solana-ai-kit) — the parent kit
- [solana-game-skill](https://github.com/solanabr/solana-game-skill) — reference skill structure
- [Solana dev skill](https://github.com/solanabr/solana-dev-skill) — core development skill
