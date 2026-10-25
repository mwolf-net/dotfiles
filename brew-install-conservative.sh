#!/bin/bash
# Install the basic packages (Brewfile): command line and developer tools. Never removes anything.
# Asks before installing Homebrew itself if it's missing.
set -euo pipefail
repo=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P)
. "$repo/lib/brew.sh"
brew_bundle "$repo/Brewfile"
