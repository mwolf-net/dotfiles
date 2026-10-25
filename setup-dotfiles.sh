#!/bin/bash
# Load this repo's shell settings and tools from your own ~/.zshrc.
#
#   ./setup-dotfiles.sh            add (or update) one marked block at the end of ~/.zshrc
#   ./setup-dotfiles.sh --remove   take that block out again
#
# The rest of ~/.zshrc stays as it is. The block points at wherever this repo is checked out,
# so after moving the repo, run this again. Updating is `git pull` in the repo; nothing runs
# by itself.
set -euo pipefail
repo=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
. "$repo/lib/block.sh"

if [ "${1:-}" = --remove ]; then
    block_remove "$HOME/.zshrc" zshrc '#'
    exit 0
fi

block_set "$HOME/.zshrc" zshrc '#' bottom \
"[[ -f \"$repo/shell/zshrc\" ]] && source \"$repo/shell/zshrc\""
echo "Open a new terminal (or: source ~/.zshrc) to use it."
