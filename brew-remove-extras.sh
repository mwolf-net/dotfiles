#!/bin/bash
# brew-remove-extras: turn a full machine back into a basic one. Uninstalls the Brewfile.extra
# packages that were installed after this repo was cloned (so most likely by brew-install-full.sh),
# and keeps everything that was there before.
#
#   ./brew-remove-extras.sh              dry run: show what would be removed and kept, and why
#   ./brew-remove-extras.sh --yes        do it
#   ./brew-remove-extras.sh --since "2026-10-25 20:00"   other cutoff (default: when this repo was cloned)
#
# "Installed after the cutoff" = Homebrew created the package's directory after it. Packages that
# something you installed yourself (and that stays) still needs are kept, and so are renamed casks,
# whose original install date is unknown. Uninstalls are plain (no --zap), so app settings survive.
set -euo pipefail

src="$(cd "$(dirname "$0")/.." && pwd)"
extra="$src/Brewfile.extra"
apply=false
cutoff=

while [ $# -gt 0 ]; do
    case "$1" in
        --yes) apply=true ;;
        --since) shift; cutoff=$(date -j -f '%Y-%m-%d %H:%M' "$1" +%s) ;;
        *) echo "usage: $0 [--yes] [--since 'YYYY-MM-DD HH:MM']" >&2; exit 2 ;;
    esac
    shift
done
if [ -z "$cutoff" ]; then
    [ -d "$src/.git" ] || { echo "No $src/.git; pass --since." >&2; exit 1; }
    cutoff=$(stat -f %B "$src/.git")
fi
echo "Cutoff: $(date -r "$cutoff" '+%Y-%m-%d %H:%M') (installed after this = candidates for removal)"
echo

cellar=$(brew --cellar)
caskroom=$(brew --caskroom)
remove_formulae=() remove_casks=()

# Entries of Brewfile.extra: "brew name" / "cask name" (tap prefix stripped)
while read -r kind name; do
    name=${name##*/}
    if [ "$kind" = brew ]; then dir="$cellar/$name"; else dir="$caskroom/$name"; fi
    if [ ! -e "$dir" ]; then
        printf '  %-28s not installed\n' "$name"
    elif [ "$kind" = cask ] && renamed_from=$(find "$caskroom" -maxdepth 1 -type l -lname "*$name" -exec basename {} \; | head -1) \
            && [ -n "$renamed_from" ]; then
        # A rename recreates the directory, so its date says nothing; play safe.
        printf '  %-28s keep: renamed from %s, original install date unknown (remove by hand if unwanted)\n' "$name" "$renamed_from"
    elif [ "$(stat -f %B "$dir")" -le "$cutoff" ]; then
        printf '  %-28s keep: was already installed (%s)\n' "$name" "$(date -r "$(stat -f %B "$dir")" '+%Y-%m-%d')"
    elif [ "$kind" = brew ]; then
        remove_formulae+=("$name")
    else
        remove_casks+=("$name")
    fi
done < <(sed -n -E 's/^(brew|cask) "([^"]+)".*/\1 \2/p' "$extra")

# A formula that something you installed yourself (and that stays) depends on must stay too.
# Dependents that Homebrew installed only as dependencies don't count: `brew autoremove` removes
# them once nothing needs them.
on_request=" $(brew list --installed-on-request 2>/dev/null | tr '\n' ' ') $(brew list --cask | tr '\n' ' ') "
removing=" ${remove_formulae[*]+"${remove_formulae[*]}"} ${remove_casks[*]+"${remove_casks[*]}"} "
keep_needed=()
final_formulae=()
for f in ${remove_formulae[@]+"${remove_formulae[@]}"}; do
    needed_by=()
    while read -r user; do
        [ -z "$user" ] && continue
        case "$removing" in *" $user "*) continue ;; esac
        case "$on_request" in *" $user "*) needed_by+=("$user") ;; esac
    done < <(brew uses --installed --recursive "$f" 2>/dev/null)
    if [ ${#needed_by[@]} -gt 0 ]; then
        keep_needed+=("$f (needed by ${needed_by[*]})")
    else
        final_formulae+=("$f")
    fi
done

for k in ${keep_needed[@]+"${keep_needed[@]}"}; do printf '  %s\n' "keep: $k"; done
echo
echo "To remove (installed after the cutoff):"
for f in ${final_formulae[@]+"${final_formulae[@]}"} ${remove_casks[@]+"${remove_casks[@]}"}; do printf '  %s\n' "$f"; done
[ ${#final_formulae[@]} -eq 0 ] && [ ${#remove_casks[@]} -eq 0 ] && { echo "  (nothing)"; exit 0; }

if ! $apply; then
    echo
    echo "Dry run. Run again with --yes to uninstall these."
    exit 0
fi
[ ${#remove_casks[@]} -gt 0 ] && brew uninstall --cask "${remove_casks[@]}"
# --ignore-dependencies: what still depends on these is only dependency-installed (see above),
# and goes with autoremove below.
[ ${#final_formulae[@]} -gt 0 ] && brew uninstall --ignore-dependencies "${final_formulae[@]}"
# Dependencies only these packages needed. Homebrew only removes ones it installed as
# dependencies, never anything you installed yourself.
brew autoremove
