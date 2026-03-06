#!/usr/bin/env bash

# Get current directory
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Export paths for Quickshell
export QML2_IMPORT_PATH="$DIR/imports:$QML2_IMPORT_PATH"
export QML_XHR_ALLOW_FILE_READ=1

# Change theme here if you want
export QS_THEME="${1:-Genshin}"

echo "Locking with Quickshell using theme: $QS_THEME"

# Run the shell
quickshell -p "$DIR/shell.qml"
