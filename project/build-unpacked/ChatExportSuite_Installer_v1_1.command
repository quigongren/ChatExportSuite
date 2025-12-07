#!/bin/zsh
# ChatExportSuite One-Click Installer v1.1 – Install / Update / Repair / Uninstall

set -euo pipefail

LOG_DIR="$HOME/Documents/CashDevInstallLogs"
mkdir -p "$LOG_DIR"
TIMESTAMP="$(date '+%Y-%m-%d_%H-%M-%S')"
LOG_FILE="$LOG_DIR/ChatExportSuite_InstallReport_${TIMESTAMP}.txt"
exec > >(tee "$LOG_FILE") 2>&1

echo "=== ChatExportSuite One-Click Installer v1.1 ==="
echo "Started: $(date)"
echo "Log file: $LOG_FILE"
echo

DEV_ROOT="/Users/carlgren/Documents/Development"
GITHUB_ROOT_DEFAULT="/Users/carlgren/Documents/GitHub"
PROJECT_ROOT="${DEV_ROOT}/chat-export-suite-v3_2"

SWIFTBAR_PLUGIN_DIR="$HOME/Library/Application Support/SwiftBar/plugins"
BACKUP_DIR="${PROJECT_ROOT}/backups"
BUILD_UNPACKED="${PROJECT_ROOT}/build-unpacked"
BUILD_OUTPUT="${PROJECT_ROOT}/build-output"
ZIP_NAME="ChatExportSuite_v3_3_2.zip"

HELPER_ROOT="${PROJECT_ROOT}/macos-helper-v2_0"
HELPER_NODE="${HELPER_ROOT}/helper.mjs"
HELPER_CLI="${HELPER_ROOT}/cli/helper-docx.sh"

HUB_SRC="${PROJECT_ROOT}/integrations/swiftbar/cashdev-hub.5m.sh"
HUB_DEST="${SWIFTBAR_PLUGIN_DIR}/cashdev-hub.5m.sh"
AI_SRC="${PROJECT_ROOT}/integrations/swiftbar/cashdev-ai.5m.sh"
AI_DEST="${SWIFTBAR_PLUGIN_DIR}/cashdev-ai.5m.sh"

if [[ ! -d "$PROJECT_ROOT" ]]; then
  echo "ERROR: Project root not found at:"
  echo "  $PROJECT_ROOT"
  echo "Aborting."
  exit 1
fi

echo "[OK] Project root: $PROJECT_ROOT"
echo

echo "Select mode:"
echo "  1) Install / Update (default)"
echo "  2) Repair"
echo "  3) Uninstall plugins"
read "mode?Choice [1-3, default 1]: "
mode="${mode:-1}"
echo

INSTALL_MODE=0
REPAIR_MODE=0
UNINSTALL_MODE=0
case "$mode" in
  1) INSTALL_MODE=1 ;;
  2) REPAIR_MODE=1 ;;
  3) UNINSTALL_MODE=1 ;;
  *) INSTALL_MODE=1 ;;
esac

echo "=== GitHub configuration ==="
echo "Default GitHub root: $GITHUB_ROOT_DEFAULT"
read "ans?Use default GitHub root? [Y/n]: "
if [[ "$ans" == "n" || "$ans" == "N" ]]; then
  read "GITHUB_ROOT?Enter full path to GitHub root (e.g. /Users/carlgren/Documents/GitHub): "
  GITHUB_ROOT="${GITHUB_ROOT:-$GITHUB_ROOT_DEFAULT}"
else
  GITHUB_ROOT="$GITHUB_ROOT_DEFAULT"
fi
mkdir -p "$GITHUB_ROOT"
echo "[OK] Using GitHub root: $GITHUB_ROOT"
echo

if ! command -v git >/dev/null 2>&1; then
  echo "WARNING: git not found, skipping repo cloning."
  GIT_AVAILABLE=0
else
  GIT_AVAILABLE=1
fi

clone_repo_if_missing() {
  local name="$1"
  local url="$2"
  local target="${GITHUB_ROOT}/${name}"

  echo "---"
  echo "Repository: $name"
  echo "Remote:     $url"
  echo "Local path: $target"

  if [[ "$GIT_AVAILABLE" -ne 1 ]]; then
    echo "Skipping clone (git not available)."
    return
  fi

  if [[ -d "$target/.git" ]]; then
    echo "[OK] Local repo already exists at $target"
    return
  fi

  read "cans?Clone this repo now? [y/N]: "
  if [[ "$cans" == "y" || "$cans" == "Y" ]]; then
    mkdir -p "$GITHUB_ROOT"
    echo "Cloning into $target ..."
    if git clone "$url" "$target"; then
      echo "[OK] Clone completed."
    else
      echo "WARNING: git clone failed for $url"
    fi
  else
    echo "Skipped cloning $name."
  fi
}

echo "=== Checking known GitHub repos ==="
clone_repo_if_missing "DriveOps-Project" "https://github.com/quigongren/DriveOps-Project.git"
clone_repo_if_missing "CashDev" "https://github.com/quigongren/CashDev.git"
clone_repo_if_missing "gren-project-dashboard" "https://github.com/quigongren/gren-project-dashboard.git"
clone_repo_if_missing "tahoe-chrome-megasuite" "https://github.com/quigongren/tahoe-chrome-megasuite.git"
clone_repo_if_missing "swiftdev" "https://github.com/quigongren/swiftdev.git"

echo
echo "Note: ChatExportSuite and CJG-Multiverse repos do not exist on GitHub yet."
echo "You can create them later under:"
echo "  ${GITHUB_ROOT}/ChatExportSuite"
echo "  ${GITHUB_ROOT}/CJG-Multiverse"
echo

if [[ "$UNINSTALL_MODE" -eq 1 ]]; then
  echo "=== Uninstalling SwiftBar plugins ==="
  if [[ -f "$HUB_DEST" ]]; then
    rm -f "$HUB_DEST"
    echo "[OK] Removed Hub plugin: $HUB_DEST"
  else
    echo "Hub plugin not present at $HUB_DEST"
  fi
  if [[ -f "$AI_DEST" ]]; then
    rm -f "$AI_DEST"
    echo "[OK] Removed AI plugin: $AI_DEST"
  else
    echo "AI plugin not present at $AI_DEST"
  fi
  echo
  echo "Uninstall mode finished. Helper and project files were left intact."
  echo "Installer completed at: $(date)"
  echo "Log file: $LOG_FILE"
  exit 0
fi

echo "=== Building ChatExportSuite Chrome extension ==="
mkdir -p "$BACKUP_DIR"
if [[ -d "$BUILD_UNPACKED" || -d "$BUILD_OUTPUT" ]]; then
  BACKUP_ARCHIVE="${BACKUP_DIR}/ChatExportSuite_build_backup_${TIMESTAMP}.tgz"
  echo "[1/4] Backing up existing build to:"
  echo "      $BACKUP_ARCHIVE"
  tar czf "$BACKUP_ARCHIVE" -C "$PROJECT_ROOT"         $( [[ -d "$BUILD_UNPACKED" ]] && echo "build-unpacked" )         $( [[ -d "$BUILD_OUTPUT" ]] && echo "build-output" ) ||         echo "WARNING: backup failed (continuing)."
else
  echo "[1/4] No previous build to back up."
fi

echo "[2/4] Cleaning build directories..."
rm -rf "$BUILD_UNPACKED" "$BUILD_OUTPUT"
mkdir -p "$BUILD_UNPACKED" "$BUILD_OUTPUT"

echo "[3/4] Running build (if package.json exists)..."
if [[ -f "${PROJECT_ROOT}/package.json" ]]; then
  cd "$PROJECT_ROOT"
  if [[ ! -d "${PROJECT_ROOT}/node_modules" ]]; then
    echo "Running npm install..."
    npm install || echo "WARNING: npm install failed."
  fi
  echo "Running npm run build..."
  npm run build || echo "WARNING: npm run build failed."
else
  echo "No package.json; using raw sources."
fi

echo "[4/4] Populating build-unpacked and creating ZIP..."
cd "$PROJECT_ROOT"
rsync -a       --exclude "build-unpacked"       --exclude "build-output"       --exclude "backups"       --exclude ".git"       --exclude "node_modules"       "$PROJECT_ROOT/" "$BUILD_UNPACKED/"

cd "$BUILD_UNPACKED"
if zip -r "$BUILD_OUTPUT/$ZIP_NAME" . >/dev/null 2>&1; then
  echo "[OK] Extension ZIP created:"
  echo "     $BUILD_OUTPUT/$ZIP_NAME"
else
  echo "WARNING: Failed to create ZIP."
fi
echo

echo "=== Validating macOS Helper v2.0 ==="
if [[ -d "$HELPER_ROOT" ]]; then
  echo "[OK] Helper root found at: $HELPER_ROOT"
  if [[ -f "$HELPER_NODE" ]]; then
    chmod +x "$HELPER_NODE" || true
    echo "[OK] helper.mjs executable."
  else
    echo "WARNING: helper.mjs missing at $HELPER_NODE"
  fi
  if [[ -f "$HELPER_CLI" ]]; then
    chmod +x "$HELPER_CLI" || true
    echo "[OK] helper-docx.sh executable."
  else
    echo "WARNING: helper-docx.sh missing at $HELPER_CLI"
  fi
else
  echo "WARNING: Helper root not found at: $HELPER_ROOT"
fi
echo

echo "=== Installing / Repairing SwiftBar plugins ==="
mkdir -p "$SWIFTBAR_PLUGIN_DIR"
if [[ -f "$HUB_SRC" ]]; then
  cp "$HUB_SRC" "$HUB_DEST"
  chmod +x "$HUB_DEST" || true
  echo "[OK] Hub plugin installed to $HUB_DEST"
else
  echo "WARNING: Hub source not found at $HUB_SRC"
fi

if [[ -f "$AI_SRC" ]]; then
  cp "$AI_SRC" "$AI_DEST"
  chmod +x "$AI_DEST" || true
  echo "[OK] AI plugin installed to $AI_DEST"
else
  echo "WARNING: AI source not found at $AI_SRC"
fi
echo

echo "Requesting SwiftBar refresh (if running)..."
osascript <<'EOF' 2>/dev/null
tell application "System Events"
  if (name of processes) contains "SwiftBar" then
    try
      tell application "SwiftBar" to refresh all plugins
    end try
  end if
end tell
EOF
echo "[OK] SwiftBar refresh requested."
echo

echo "=== SUMMARY ==="
echo "Mode:              $([[ "$REPAIR_MODE" -eq 1 ]] && echo Repair || echo Install/Update)"
echo "Project root:      $PROJECT_ROOT"
echo "GitHub root:       $GITHUB_ROOT"
echo "Helper root:       $HELPER_ROOT"
echo "Hub plugin dest:   $HUB_DEST"
echo "AI plugin dest:    $AI_DEST"
echo "Build-unpacked:    $BUILD_UNPACKED"
echo "Build-output ZIP:  $BUILD_OUTPUT/$ZIP_NAME"
echo
echo "Installer completed at: $(date)"
echo "Full log file: $LOG_FILE"

open "$LOG_FILE" 2>/dev/null || true

exit 0
