#!/bin/zsh
# macOS Helper v2.0 – Markdown → DOCX wrapper

set -euo pipefail

ROOT="/Users/carlgren/Documents/Development/chat-export-suite-v3_2/macos-helper-v2_0"
NODE_HELPER="${ROOT}/helper.mjs"

IN_MD="${1:-}"
OUT_DOCX="${2:-}"

if [[ -z "$IN_MD" || -z "$OUT_DOCX" ]]; then
  echo "[helper-docx] Usage: helper-docx.sh /full/path/input.md /full/path/output.docx" >&2
  exit 1
fi

node "$NODE_HELPER" md-to-docx "$IN_MD" "$OUT_DOCX"
