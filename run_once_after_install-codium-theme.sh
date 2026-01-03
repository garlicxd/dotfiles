#!/bin/bash

# URL fetched from DMS Docs (Application Theming section)
VSIX_URL="https://github.com/AvengeMedia/DankMaterialShell/raw/refs/heads/master/quickshell/matugen/dynamic-base16-dankshell.vsix"
VSIX_FILE="/tmp/dynamic-base16-dankshell.vsix"

# 1. Download the VSIX file (One-liner style)
echo "📥 Downloading Dank16 Base16 Extension..."
wget -qO "$VSIX_FILE" "$VSIX_URL" || curl -L -o "$VSIX_FILE" "$VSIX_URL"

# 2. Define target editors
EDITORS=("code-insiders" "antigravity")

# 3. Install to both
for editor in "${EDITORS[@]}"; do
    if command -v "$editor" &> /dev/null; then
        echo "🚀 Installing Dank16 VSIX for $editor..."
        "$editor" --install-extension "$VSIX_FILE" --force
    else
        echo "⚠️  $editor command not found, skipping..."
    fi
done

# 4. Cleanup
rm "$VSIX_FILE"
echo "✅ Installation complete. Please select 'Dynamic Base16 DankShell' in your color themes."
