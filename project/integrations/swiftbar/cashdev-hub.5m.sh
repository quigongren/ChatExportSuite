#!/bin/zsh
# CashDev Hub v4.1 – SwiftBar HUD Plugin

PATH="/usr/local/bin:/opt/homebrew/bin:/usr/bin:/bin:/usr/sbin:/sbin"

detect_chrome_url() {
  /usr/bin/osascript << 'EOF' 2>/dev/null
tell application "System Events"
  if (name of processes) does not contain "Google Chrome" then
    return ""
  end if
end tell

tell application "Google Chrome"
  if (count of windows) is 0 then return "" end if
  set activeTab to active tab of front window
  return URL of activeTab
end tell
EOF
}

detect_chrome_perf() {
  local url
  url="$(detect_chrome_url)"
  if [[ -z "$url" ]]; then
    echo "Low"
    return
  fi

  if [[ "$url" == *"chatgpt.com"* ]] || [[ "$url" == *"openai.com"* ]]; then
    echo "High"
  else
    echo "Low"
  fi
}

ai_connectivity_status() {
  local code
  code="$(curl -s -o /dev/null -w "%{http_code}" "https://chatgpt.com" || echo "000")"
  if [[ "$code" == "200" ]]; then
    echo "OK"
  else
    echo "Issue ($code)"
  fi
}

LOG_DIR="$HOME/Documents/CashDevInstallLogs"
PROJECT_ROOT="/Users/carlgren/Documents/Development/chat-export-suite-v3_2"
DRIVEOPS_ROOT="/Users/carlgren/Documents/GitHub/DriveOps-Project"
INSTALLER="$PROJECT_ROOT/ChatExportSuite_Installer_v1_1.command"
HELPER_ROOT="${PROJECT_ROOT}/macos-helper-v2_0"

latest_helper_log() {
  if [[ -d "$LOG_DIR" ]]; then
    local latest
    latest="$(ls -t "$LOG_DIR"/helper_v2.0_*.log 2>/dev/null | head -n 1)"
    if [[ -n "$latest" ]]; then
      echo "${latest##*/}"
      return
    fi
  fi
  echo "None"
}

perf_level="$(detect_chrome_perf)"
perf_icon="●"
perf_color="yellow"
if [[ "$perf_level" == "High" ]]; then
  perf_color="green"
elif [[ "$perf_level" == "Low" ]]; then
  perf_color="red"
fi

ai_status="$(ai_connectivity_status)"
ai_color="yellow"
if [[ "$ai_status" == "OK" ]]; then
  ai_color="green"
else
  ai_color="red"
fi

helper_log_file="$(latest_helper_log)"

echo "CashDev Hub"
echo "---"

echo "Multiverse Engine ▸ | color=#cccccc"
echo "--Universe Manager (Open Project Root)… | bash='/usr/bin/open' param1="$PROJECT_ROOT" terminal=false"
echo "--Open Multiverse Root (GitHub)… | bash='/usr/bin/open' param1="$HOME/Documents/GitHub" terminal=false"
echo "--Open Logs Folder… | bash='/usr/bin/open' param1="$LOG_DIR" terminal=false"
echo "-----"

echo "Chrome / GPT HUD ▸ | color=#cccccc"
echo "--Chrome Performance: $perf_icon $perf_level | color=$perf_color"
echo "--AI Connectivity: $ai_status | color=$ai_color"
echo "--Open Chrome | bash='/usr/bin/open' param1='-a' param2='Google Chrome' terminal=false"
echo "--Reload Extensions (Chrome Extensions Page) | bash='/usr/bin/open' param1='chrome://extensions' terminal=false"
echo "-----"

echo "Helper v2.0 ▸ | color=#cccccc"
echo "--Helper Root: $HELPER_ROOT | color=#aaaaaa"
echo "--Latest Helper Log: $helper_log_file | color=#aaaaaa"
echo "--Open Helper Folder… | bash='/usr/bin/open' param1="$HELPER_ROOT" terminal=false"
echo "--Open Helper Logs… | bash='/usr/bin/open' param1="$LOG_DIR" terminal=false"
echo "-----"

echo "DriveOps & Sync ▸ | color=#cccccc"
echo "--Open DriveOps Project… | bash='/usr/bin/open' param1="$DRIVEOPS_ROOT" terminal=false"
echo "--Open CashDev Install Logs… | bash='/usr/bin/open' param1="$LOG_DIR" terminal=false"
echo "-----"

echo "Diagnostics ▸ | color=#cccccc"
echo "--Open SwiftBar Preferences… | bash='/usr/bin/open' param1='swiftbar://' terminal=false"
echo "--Check Plugin Folder… | bash='/usr/bin/open' param1="$HOME/Library/Application Support/SwiftBar/plugins" terminal=false"
echo "--Show Logs Folder… | bash='/usr/bin/open' param1="$LOG_DIR" terminal=false"
echo "-----"

echo "Repair Tools ▸ | color=#cccccc"
echo "--Restart SwiftBar | bash='killall' param1='SwiftBar' terminal=false"
echo "-----"

echo "SwiftBar Integration ▸ | color=#cccccc"
echo "--Open SwiftBar | bash='/usr/bin/open' param1='-a' param2='SwiftBar' terminal=false"
