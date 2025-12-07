#!/bin/zsh
# macOS Helper v2.0 – Markdown → DOCX → PDF wrapper

set -euo pipefail

ROOT="/Users/carlgren/Documents/Development/chat-export-suite-v3_2/macos-helper-v2_0"
NODE_HELPER="${ROOT}/helper.mjs"

IN_MD="${1:-}"
OUT_DOCX="${2:-}"
OUT_PDF="${3:-}"

if [[ -z "$IN_MD" || -z "$OUT_DOCX" || -z "$OUT_PDF" ]]; then
  echo "[helper-docx-pdf] Usage: helper-docx-pdf.sh /full/path/input.md /full/path/output.docx /full/path/output.pdf" >&2
  exit 1
fi

node "$NODE_HELPER" md-to-docx-pdf "$IN_MD" "$OUT_DOCX" "$OUT_PDF"
