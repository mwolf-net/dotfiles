# Shared by the brew-install scripts.
# shellcheck source=lib/block.sh
. "$(dirname "${BASH_SOURCE[0]}")/block.sh"

if ! command -v brew >/dev/null; then
    if [ -x /opt/homebrew/bin/brew ]; then
        eval "$(/opt/homebrew/bin/brew shellenv)"
    elif ask_yes_no "Homebrew isn't installed. Install it now (from brew.sh)?"; then
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        eval "$(/opt/homebrew/bin/brew shellenv)"
    else
        exit 1
    fi
fi

brew_bundle() {
    echo "==> brew bundle --file $1"
    brew bundle --file "$1" || echo "Some packages failed; run it again: brew bundle --file $1"
}
