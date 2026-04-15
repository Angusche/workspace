# Directories to ignore during search
IGNORE_DIRS=(.git)

_cdb_find() {
    local root="$1"
    local name="$2"
    local mode="$3"
    local -a find_cmd=()
    local i dir

    find_cmd=(find "$root")

    if [ ${#IGNORE_DIRS[@]} -gt 0 ]; then
        find_cmd+=( "(" -type d "(" )
        for i in "${!IGNORE_DIRS[@]}"; do
            [ "$i" -gt 0 ] && find_cmd+=( -o )
            find_cmd+=( -name "${IGNORE_DIRS[$i]}" )
        done
        find_cmd+=( ")" -prune ")" -o )
    fi

    if [ "$mode" = "exact" ]; then
        find_cmd+=( -type d -iname "$name" -print )
    else
        find_cmd+=( -type d -iname "*$name*" -print )
    fi

    "${find_cmd[@]}" 2>/dev/null
}

_cdb_pick() {
    local -a matches=("$@")
    local i sel

    if [ ${#matches[@]} -eq 0 ]; then
        return 1
    elif [ ${#matches[@]} -eq 1 ]; then
        builtin cd "${matches[0]}" || return 1
        pwd
        return 0
    fi

    echo "Multiple matches found:"
    for i in "${!matches[@]}"; do
        printf '  [%d] %s\n' "$((i + 1))" "${matches[$i]}"
    done

    read -rp "Choose number: " sel

    if [[ "$sel" =~ ^[0-9]+$ ]] && [ "$sel" -ge 1 ] && [ "$sel" -le ${#matches[@]} ]; then
        builtin cd "${matches[$((sel - 1))]}" || return 1
        pwd
        return 0
    fi

    echo "Invalid selection" >&2
    return 1
}

_cdb_go() {
    local root="$1"
    local name="$2"
    local -a exact_matches=()
    local -a partial_matches=()
    local line

    if [ -z "$name" ]; then
        echo "Usage: cdb <folder-name>" >&2
        return 1
    fi

    while IFS= read -r line; do
        [ -n "$line" ] && exact_matches+=("$line")
    done < <(_cdb_find "$root" "$name" exact)

    if [ ${#exact_matches[@]} -gt 0 ]; then
        _cdb_pick "${exact_matches[@]}"
        return
    fi

    while IFS= read -r line; do
        [ -n "$line" ] && partial_matches+=("$line")
    done < <(_cdb_find "$root" "$name" partial)

    if [ ${#partial_matches[@]} -gt 0 ]; then
        _cdb_pick "${partial_matches[@]}"
        return
    fi

    echo "No matching directory found: $name" >&2
    return 1
}

# Search from current directory
cdd() {
    _cdb_go "." "$1"
}

# Search from home directory
cddh() {
    _cdb_go "$HOME" "$1"
}
