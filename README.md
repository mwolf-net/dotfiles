# dotfiles

Small, separate scripts for setting up a Mac: Homebrew packages, a vim configuration, shell
settings and a few macOS tweaks. Use any of them on its own.

Your existing files are never replaced. The setup scripts add one marked block that loads the
file from this repo, keep the rest of your file as it is, and keep a copy of the original as
`<file>.before-dotfiles`. Running a script again updates its block in place (for instance after
moving the repo), and `--remove` takes it out again. Nothing runs in the background: to update,
`git pull` in the repo.

Clone it anywhere; the scripts find the repo from their own location.

## Scripts

| Script | What it does |
|---|---|
| `brew-install-conservative.sh` | `brew bundle` with `Brewfile`: command line and developer tools, small enough for any machine |
| `brew-install-full.sh` | `Brewfile` plus `Brewfile.extra`: JVM, cloud CLIs, media and map tools, local AI, TeX (several GB) |
| `brew-remove-extras.sh` | Uninstall the `Brewfile.extra` packages installed after the repo was cloned; dry run unless `--yes` |
| `setup-vim.sh` | Load `vim/vimrc` from `~/.vimrc`; set up vim-plug and plugins in `~/.vim` (asks before replacing an existing `~/.vim`) |
| `setup-dotfiles.sh` | Load `shell/zshrc` from `~/.zshrc`: aliases, and this repo's `bin/` on the PATH if there is one |
| `setup-macos-tweaks.sh` | Touch ID for sudo, no `.DS_Store` files on network shares, Chrome without Cast discovery; asks about each. `--undo` reverses them |

The brew scripts never uninstall anything and ask before installing Homebrew itself.

## Git

`git/gitconfig.sample` is a starting point for `~/.gitconfig`: copy what you want. No script writes
your git configuration. `git/ignore` is a global gitignore to use with `core.excludesFile`.

## Removing it

```
./setup-dotfiles.sh --remove
./setup-vim.sh --remove
./setup-macos-tweaks.sh --undo
```

Then delete the clone. Packages stay installed; `brew-remove-extras.sh` removes the extras.
