#!/bin/bash
# Install the basic packages (Brewfile) plus the extras (Brewfile.extra: several GB, some casks
# ask for your password). Never removes anything. Asks before installing Homebrew if it's missing.
set -euo pipefail
repo=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
. "$repo/lib/brew.sh"
brew_bundle "$repo/Brewfile"
brew_bundle "$repo/Brewfile.extra"
