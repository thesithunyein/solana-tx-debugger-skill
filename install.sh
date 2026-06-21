#!/usr/bin/env bash
set -euo pipefail

# solana-tx-debugger-skill — Standard Installer
# Installs the skill into your Claude Code / Codex configuration.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_NAME="solana-tx-debugger-skill"

# Default target: ~/.claude/skills/
TARGET_DIR="${HOME}/.claude/skills/${SKILL_NAME}"

echo "Installing ${SKILL_NAME}..."
echo "Target: ${TARGET_DIR}"

# Create target directory
mkdir -p "${TARGET_DIR}"

# Copy skill files
cp -r "${SCRIPT_DIR}/skill" "${TARGET_DIR}/skill"
cp -r "${SCRIPT_DIR}/agents" "${TARGET_DIR}/agents" 2>/dev/null || true
cp -r "${SCRIPT_DIR}/commands" "${TARGET_DIR}/commands" 2>/dev/null || true
cp -r "${SCRIPT_DIR}/rules" "${TARGET_DIR}/rules" 2>/dev/null || true
cp "${SCRIPT_DIR}/CLAUDE.md" "${TARGET_DIR}/CLAUDE.md" 2>/dev/null || true

echo ""
echo "✅ ${SKILL_NAME} installed to ${TARGET_DIR}"
echo ""
echo "Usage: Ask Claude Code to debug a Solana transaction, or use:"
echo "  /debug-tx <tx-signature>"
echo ""
echo "To uninstall: rm -rf ${TARGET_DIR}"
