#!/bin/bash
# A few macOS settings, each one asked separately.
#
#   ./setup-macos-tweaks.sh          ask about each tweak that isn't on yet
#   ./setup-macos-tweaks.sh --undo   ask about undoing each tweak that is on
set -euo pipefail
repo=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
. "$repo/lib/block.sh"
undo=false
[ "${1:-}" = --undo ] && undo=true

# tweak "description" check-command do-command undo-command
tweak() {
    local what=$1 check=$2 do=$3 undo_cmd=$4
    echo
    if eval "$check" >/dev/null 2>&1; then
        if $undo; then
            ask_yes_no "Undo: $what?" && eval "$undo_cmd" && echo "  undone"
        else
            echo "Already on: $what"
        fi
    else
        if $undo; then
            echo "Not on: $what"
        else
            ask_yes_no "$what?" && eval "$do" && echo "  done"
        fi
    fi
    return 0
}

tweak "Touch ID for sudo (writes /etc/pam.d/sudo_local, which survives macOS updates; asks for your password)" \
    "grep -qs '^auth.*pam_tid.so' /etc/pam.d/sudo_local" \
    "sed 's/^#auth/auth/' /etc/pam.d/sudo_local.template | sudo tee /etc/pam.d/sudo_local >/dev/null" \
    "sudo rm /etc/pam.d/sudo_local"

tweak "Finder: don't write .DS_Store files on network shares" \
    "[ \"\$(defaults read com.apple.desktopservices DSDontWriteNetworkStores 2>/dev/null)\" = 1 ]" \
    "defaults write com.apple.desktopservices DSDontWriteNetworkStores -bool true" \
    "defaults delete com.apple.desktopservices DSDontWriteNetworkStores"

tweak "Chrome: turn off Cast device discovery (stops its local-network prompts; no Cast button, and Chrome shows 'Managed by your organization'; restart Chrome after)" \
    "[ \"\$(defaults read com.google.Chrome EnableMediaRouter 2>/dev/null)\" = 0 ]" \
    "defaults write com.google.Chrome EnableMediaRouter -bool false" \
    "defaults delete com.google.Chrome EnableMediaRouter"
