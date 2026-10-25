# Shared by the setup scripts: keep one marked block in a file up to date, or remove it, without
# touching anything else in the file. Source this file; it defines block_set and block_remove.
#
# A block looks like this (with the file's comment character):
#   # >>> dotfiles:NAME >>>
#   ...lines...
#   # <<< dotfiles:NAME <<<
#
# Before the first change to a file, a copy is kept as FILE.before-dotfiles.

# block_set FILE NAME COMMENT_CHAR top|bottom TEXT
#   Replaces the block in place if it's there, otherwise adds it at the top or bottom.
block_set() {
    local file=$1 name=$2 c=$3 pos=$4 text=$5
    local begin="$c >>> dotfiles:$name >>>" end="$c <<< dotfiles:$name <<<"
    local blk tmp
    if [ -e "$file" ] && [ "$(grep -cxF "$begin" "$file")" -gt 1 ]; then
        echo "  $file has more than one dotfiles:$name block; fix it by hand." >&2
        return 1
    fi
    blk=$(mktemp) tmp=$(mktemp)
    printf '%s\n%s\n%s\n' "$begin" "$text" "$end" > "$blk"
    if [ -e "$file" ] && grep -qxF "$begin" "$file"; then
        awk -v b="$begin" -v e="$end" -v blk="$blk" '
            $0 == b { while ((getline l < blk) > 0) print l; skip = 1; next }
            skip && $0 == e { skip = 0; next }
            !skip { print }' "$file" > "$tmp"
    elif [ ! -s "$file" ]; then
        cat "$blk" > "$tmp"
    elif [ "$pos" = top ]; then
        { cat "$blk"; echo; cat "$file"; } > "$tmp"
    else
        { cat "$file"; [ -n "$(tail -c1 "$file")" ] && echo; echo; cat "$blk"; } > "$tmp"
    fi
    _block_write "$file" "$tmp" "added/updated dotfiles:$name"
    rm -f "$blk"
}

# block_remove FILE NAME COMMENT_CHAR
#   Removes the block and the blank separator line block_set added with it.
block_remove() {
    local file=$1 name=$2 c=$3
    local begin="$c >>> dotfiles:$name >>>" end="$c <<< dotfiles:$name <<<" tmp
    if [ ! -e "$file" ] || ! grep -qxF "$begin" "$file"; then
        echo "  $file: no dotfiles:$name block"
        return 0
    fi
    tmp=$(mktemp)
    awk -v b="$begin" -v e="$end" '
        { line[NR] = $0 }
        $0 == b { bi = NR } $0 == e && bi && !ei { ei = NR }
        END {
            from = bi; to = ei
            if (bi == 1 && line[ei + 1] == "") to = ei + 1
            else if (ei == NR && bi > 1 && line[bi - 1] == "") from = bi - 1
            for (i = 1; i <= NR; i++) if (i < from || i > to) print line[i]
        }' "$file" > "$tmp"
    _block_write "$file" "$tmp" "removed dotfiles:$name"
}

_block_write() {
    local file=$1 tmp=$2 what=$3
    if [ -e "$file" ] && cmp -s "$tmp" "$file"; then
        echo "  $file: already up to date"
    else
        [ -e "$file" ] && [ ! -e "$file.before-dotfiles" ] && cp -p "$file" "$file.before-dotfiles"
        cat "$tmp" > "$file"    # keeps the file's permissions, and symlinks stay symlinks
        echo "  $file: $what"
    fi
    rm -f "$tmp"
}

# ask_yes_no "question": keeps asking until the answer is yes/y or no/n. Returns 0 for yes.
ask_yes_no() {
    local answer
    while true; do
        if ! read -r -p "$1 (yes/no): " answer </dev/tty; then
            echo "  No answer, stopping." >&2
            exit 1
        fi
        case "$(printf '%s' "$answer" | tr '[:upper:]' '[:lower:]')" in
            y|yes) return 0 ;;
            n|no) return 1 ;;
        esac
        echo "  Please type yes or no."
    done
}
