#!/usr/bin/env bash
set -euo pipefail

# solana-tx-debugger-skill — Custom Installer
# Installs the skill with configurable options.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
SKILL_NAME="solana-tx-debugger-skill"

# Defaults
TARGET_DIR="${HOME}/.claude/skills/${SKILL_NAME}"
INSTALL_AGENTS=true
INSTALL_COMMANDS=true
INSTALL_RULES=false

usage() {
  cat <<EOF
Usage: $0 [options]

Options:
  --target <path>       Install directory (default: ~/.claude/skills/${SKILL_NAME})
  --no-agents           Skip installing agents/
  --no-commands         Skip installing commands/
  --with-rules          Install rules/ (skipped by default)
  -h, --help            Show this help

Examples:
  $0 --target ~/.codex/skills/${SKILL_NAME}
  $0 --no-agents --no-commands
EOF
}

while [[ $# -gt 0 ]]; do
  case "$1" in
    --target)     TARGET_DIR="$2"; shift 2 ;;
    --no-agents)  INSTALL_AGENTS=false; shift ;;
    --no-commands) INSTALL_COMMANDS=false; shift ;;
    --with-rules) INSTALL_RULES=true; shift ;;
    -h|--help)    usage; exit 0 ;;
    *)            echo "Unknown option: $1"; usage; exit 1 ;;
  esac
done

echo "Installing ${SKILL_NAME}..."
echo "Target: ${TARGET_DIR}"
echo "Agents: ${INSTALL_AGENTS}  Commands: ${INSTALL_COMMANDS}  Rules: ${INSTALL_RULES}"
echo ""

mkdir -p "${TARGET_DIR}"

# Always install skill/
cp -r "${SCRIPT_DIR}/skill" "${TARGET_DIR}/skill"
cp "${SCRIPT_DIR}/CLAUDE.md" "${TARGET_DIR}/CLAUDE.md" 2>/dev/null || true

# Optional components
if [[ "${INSTALL_AGENTS}" == "true" ]]; then
  cp -r "${SCRIPT_DIR}/agents" "${TARGET_DIR}/agents" 2>/dev/null || true
fi

if [[ "${INSTALL_COMMANDS}" == "true" ]]; then
  cp -r "${SCRIPT_DIR}/commands" "${TARGET_DIR}/commands" 2>/dev/null || true
fi

if [[ "${INSTALL_RULES}" == "true" ]]; then
  cp -r "${SCRIPT_DIR}/rules" "${TARGET_DIR}/rules" 2>/dev/null || true
fi

echo "✅ ${SKILL_NAME} installed to ${TARGET_DIR}"
echo ""
echo "Usage: /debug-tx <tx-signature>"
echo "To uninstall: rm -rf ${TARGET_DIR}"
