#!/usr/bin/env bash
# Installs the latest gitdash release. Set GITDASH_INSTALL_DIR to choose where.
set -euo pipefail

REPO="adammcarter/gitdash"
DIR="${GITDASH_INSTALL_DIR:-$HOME/.local/bin}"

command -v python3 >/dev/null 2>&1 || { echo "gitdash needs python3 on your PATH." >&2; exit 1; }
command -v git >/dev/null 2>&1 || { echo "gitdash needs git on your PATH." >&2; exit 1; }

mkdir -p "$DIR"
tmp="$(mktemp)"
trap 'rm -f "$tmp"' EXIT
curl -fsSL "https://github.com/$REPO/releases/latest/download/gitdash" -o "$tmp"
chmod 755 "$tmp"
mv "$tmp" "$DIR/gitdash"

echo "Installed $("$DIR/gitdash" --version) to $DIR/gitdash"
case ":$PATH:" in
  *":$DIR:"*) echo "Run 'gitdash' inside any git repo." ;;
  *) echo "Add $DIR to your PATH, e.g. add this to your shell profile:"
     echo "  export PATH=\"$DIR:\$PATH\"" ;;
esac
