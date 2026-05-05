#!/usr/bin/env bash
# SPDX-License-Identifier: AGPL-3.0-only
set -e

echo "⚡ Cipher — Encrypted. Private. Yours."
echo ""

# Determine OS and Architecture
OS="$(uname -s)"
ARCH="$(uname -m)"

if [ "$OS" != "Linux" ]; then
    echo "Error: This install script currently only supports Linux."
    exit 1
fi

if [ "$ARCH" = "x86_64" ] || [ "$ARCH" = "amd64" ]; then
    DL_ARCH="amd64"
elif [ "$ARCH" = "aarch64" ] || [ "$ARCH" = "arm64" ]; then
    DL_ARCH="arm64"
else
    echo "Error: Unsupported architecture $ARCH."
    exit 1
fi

REPO="braxius-hq/cipher"
BINARY_PATTERN="cipher-.*-linux-${DL_ARCH}"
INSTALL_DIR="${HOME}/.local/bin"

TMPDIR="$(mktemp -d)"
BINARY="$TMPDIR/cipher"

cleanup() {
	rm -rf "$TMPDIR"
}
trap cleanup EXIT

echo "Installing latest release (~100 MB)..."
LATEST_URL=$(curl -sf https://api.github.com/repos/$REPO/releases/latest | grep "browser_download_url" | grep -E "$BINARY_PATTERN" | cut -d '"' -f 4 | head -n 1)

if [ -z "$LATEST_URL" ]; then
	echo "Error: Could not find latest release for Linux."
	exit 1
fi

curl -#fL -o "$BINARY" "$LATEST_URL"

FILE_TYPE=$(file -b "$BINARY" 2>/dev/null || true)
if ! echo "$FILE_TYPE" | grep -qi "ELF"; then
	echo "Error: Downloaded file is not a valid binary."
	echo "       Got: $FILE_TYPE"
	echo "       This may be a temporary issue. Try again later."
	exit 1
fi

chmod +x "$BINARY"
mkdir -p "$INSTALL_DIR"
mv "$BINARY" "$INSTALL_DIR/cipher"

echo ""
echo "✅ Cipher installed to $INSTALL_DIR/cipher."

if ! echo "$PATH" | tr ':' '\n' | grep -qFx "$INSTALL_DIR"; then
    echo ""
    echo "⚠️  $INSTALL_DIR is not in your PATH."
    echo "   Add this to your shell config (~/.bashrc or ~/.zshrc):"
    echo ""
    echo "   export PATH=\"\$HOME/.local/bin:\$PATH\""
    echo ""
    echo "   Then restart your terminal or run: source ~/.bashrc"
fi

echo ""
echo "Run 'cipher' to get started."