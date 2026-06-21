# CLAUDE.md — solana-tx-debugger-skill

## Project
This is a Claude Code / Codex skill for the Solana AI Kit that diagnoses failed Solana transactions.

## Skill Entry Point
All skill knowledge is in `skill/SKILL.md`. That file routes to focused sub-skills — load only what's needed for the current debugging task.

## Conventions
- **Progressive loading:** Never load all skill files at once. `SKILL.md` routes to the relevant sub-file.
- **Accuracy first:** Every error code, fix, and snippet must be verified against real on-chain behavior. No guessing.
- **Current stack:** Target the 2026 Solana stack — Token-2022, versioned transactions, ALTs, compute budget instructions.
- **MIT licensed:** All content is MIT. No proprietary code or locked APIs.

## Commands
- `/debug-tx <signature>` — runs the full tx debugging workflow (see `commands/debug-tx.md`)

## Agent
- `agents/tx-debugger.md` — agent persona for the debugging workflow

## Testing
- Verify every recipe in `skill/recipes.md` against real devnet/mainnet signatures.
- Run `install.sh` on a clean environment before submitting.
