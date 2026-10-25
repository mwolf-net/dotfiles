#!/bin/bash
# Use this repo's vimrc, with vim-plug and its plugins.
#
#   ./setup-vim.sh            add (or update) a marked line at the end of ~/.vimrc that loads
#                             vim/vimrc, then set up ~/.vim (asks first if it already exists)
#   ./setup-vim.sh --remove   take that line out of ~/.vimrc again (leaves ~/.vim alone)
#
# The rest of ~/.vimrc stays as it is.
set -euo pipefail
repo=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
. "$repo/lib/block.sh"
vimrc="$repo/vim/vimrc"

if [ "${1:-}" = --remove ]; then
    block_remove "$HOME/.vimrc" vimrc '"'
    exit 0
fi
case "$vimrc" in *'"'*|*"'"*) echo "The repo path contains a quote; vim can't load it safely." >&2; exit 1 ;; esac

block_set "$HOME/.vimrc" vimrc '"' bottom \
"if filereadable(\"$vimrc\") | execute 'source' fnameescape(\"$vimrc\") | endif"

install_plugins=true
if [ -e "$HOME/.vim" ]; then
    echo
    # shellcheck disable=SC2088  # a literal ~ in the message
    echo "~/.vim already exists ($(du -sh "$HOME/.vim" 2>/dev/null | awk '{print $1}'))."
    if ask_yes_no "Replace it with a fresh one? (the old one is moved to ~/.vim.before-dotfiles-<date>)"; then
        mv "$HOME/.vim" "$HOME/.vim.before-dotfiles-$(date +%Y%m%d-%H%M%S)"
        echo "  moved the old ~/.vim aside"
    elif ! ask_yes_no "Keep it, but add vim-plug and any missing plugins to it?"; then
        install_plugins=false
        echo "  ~/.vim left as it is; plugins not installed"
    fi
fi

if $install_plugins; then
    mkdir -p "$HOME/.vim/swapfiles"
    plug="$HOME/.vim/autoload/plug.vim"
    [ -f "$plug" ] || curl -fsSLo "$plug" --create-dirs \
        https://raw.githubusercontent.com/junegunn/vim-plug/master/plug.vim
    vim -es -u "$HOME/.vimrc" -i NONE -c 'PlugInstall --sync' -c 'qa' </dev/null || true
    echo "  vim-plug and plugins installed in ~/.vim"
fi
