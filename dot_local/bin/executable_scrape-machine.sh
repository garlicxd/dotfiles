#!/bin/bash
set -euo pipefail

# Scrapes current machine configuration (Monitors, CPU, GPU, Compute)
# Usage: ./scrape-machine.sh > hardware_snippet.toml

# 1. Get current profile
CONFIG_FILE="$HOME/.config/chezmoi/chezmoi.toml"
if [ ! -f "$CONFIG_FILE" ]; then
    echo "Error: $CONFIG_FILE not found. Cannot determine profile." >&2
    exit 1
fi
PROFILE=$(grep '^profile' "$CONFIG_FILE" | cut -d'=' -f2 | tr -d ' "')

if [ -z "$PROFILE" ]; then
    echo "Error: Copuld not extract profile from $CONFIG_FILE" >&2
    exit 1
fi

echo "# Extracted hardware config for: $(hostname)"
echo "[$PROFILE]"

# 2. Monitors (Niri)
# Only run if niri is running/available, otherwise skip using silent check
if command -v niri >/dev/null 2>&1 && pgrep niri >/dev/null; then
    niri msg outputs | awk -v profile="$PROFILE" '
        /^Output/ {
            match($0, /\(([^)]+)\)$/, arr)
            name = arr[1]
            print "[[" profile ".monitors]]"
            printf "name = \"%s\"\n", name
        }
        /Current mode:/ { printf "mode = \"%s@%s\"\n", $3, $5 }
        /Scale:/ { printf "scale = %s\n", $2 }
        /Transform:/ { if ($2 != "normal") printf "orientation = \"%s\"\n", $2 }
        /Logical position:/ { 
            gsub(",", "", $3)
            printf "position = \"x=%s y=%s\"\n", $3, $4 
        }
        /^$/ { print "" }
    '
else
    echo "# Niri not running or not found, skipping monitor scrape."
fi

echo ""

# 3. CPU Info
# Parsed from lscpu
CPU_MODEL=$(lscpu | grep "Model name:" | sed 's/Model name:\s*//')
CPU_ARCH=$(lscpu | grep "Architecture:" | awk '{print $2}')
CPU_CORES=$(lscpu | grep "^CPU(s):" | awk '{print $2}')

echo "[$PROFILE.cpu]"
echo "model = \"$CPU_MODEL\""
echo "arch = \"$CPU_ARCH\""
echo "cores = $CPU_CORES"
echo ""

# 4. GPU & Compute Capability
echo "[$PROFILE.gpu]"

# Get list of VGA/3D controllers
# Using -nn to get [vendor:device] codes if needed later, but stripped for devices list
GPU_LIST=$(lspci -nn | grep -E -i "VGA|3D" | sed 's/.*: //')

echo "devices = ["
while IFS= read -r line; do
    if [ ! -z "$line" ]; then
        echo "  \"$line\","
    fi
done <<< "$GPU_LIST"
echo "]"

# Placeholder for single compute variable
# Options: "cuda", "rocm", "xpu", "mps", "false"
echo "compute = \"false\" # TODO: Implement checking logic for cuda/rocm/xpu/mps"
echo ""
