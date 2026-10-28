#!/usr/bin/env bash
# dots.sh - symlink-based dotfiles manager driven by a dots.yaml file.
set -uo pipefail

VERSION=0.1.0
DATA_DIR=${DOTS_DATA:-${XDG_DATA_HOME:-$HOME/.local/share}/dots}
CONFIG=${DOTS_CONFIG:-./dots.yaml}
MAX_DEPTH=8
US=$'\x1f'
RS=$'\x1e'

MODE=link
DRY=0
NAMES=()
N_NEW=0 N_OK=0 N_WARN=0 N_ERR=0 N_GONE=0 N_MATCH=0

declare -A LOCK_URL=() LOCK_REF=() LOCK_COMMIT=()
declare -A NEW_SPEC=() NEW_URL=() NEW_REF=() NEW_COMMIT=()
NEW_ORDER=()

if [[ -t 1 ]]; then
    C_RED=$'\e[31m' C_GRN=$'\e[32m' C_YEL=$'\e[33m' C_DIM=$'\e[2m' C_OFF=$'\e[0m'
else
    C_RED= C_GRN= C_YEL= C_DIM= C_OFF=
fi

info() { printf '%s\n' "$*"; }
ok()   { printf '%s✓%s %s\n' "$C_GRN" "$C_OFF" "$*"; }
warn() { printf '%s!%s %s\n' "$C_YEL" "$C_OFF" "$*" >&2; N_WARN=$((N_WARN + 1)); }
err()  { printf '%s✗%s %s\n' "$C_RED" "$C_OFF" "$*" >&2; N_ERR=$((N_ERR + 1)); }
die()  { printf 'dots.sh: %s\n' "$*" >&2; exit 2; }

usage() {
    cat <<'EOF'
Usage: dots.sh [options] [command] [names...]

Commands:
  link              create symlinks, cloning remotes at their locked commit (default)
  update [names]    re-download remotes (all, or only the named ones and
                    those nested under them), rewrite dots.lock, link, then
                    run each updated remote's post_update command
  status            show state of every link, change nothing
  unlink [names]    remove symlinks that point at their configured source
                    (all, or only entries named / under the given names)

Options:
  -c, --config FILE   dots.yaml to use (default: ./dots.yaml, or $DOTS_CONFIG)
  --update NAME       same as 'update NAME'; repeatable
  -u, --undo NAME     same as 'unlink NAME'; repeatable (e.g. --undo quickshell
                      or --undo zsh/.zshrc)
  -n, --dry-run       show what would happen, change nothing
  -h, --help          show this help
  -V, --version       show version

post_update is a shell command set next to `remote:` in your dots.yaml. It runs
inside the clone, only when an update changed the commit, with DOTS_NAME,
DOTS_DIR, DOTS_OLD_COMMIT and DOTS_COMMIT in its environment.

An entry with `stow: true` mirrors the folder tree at `source:` (default ./<name>)
into `destination:` (default ~), linking files, and whole directories that do not
exist yet, like GNU stow.

An entry may use `content:` (text, usually a "|" block) instead of `source:`. It
is written to $DOTS_DATA/.content/<entry> and linked like a source.

Remotes are cloned into $DOTS_DATA (default ~/.local/share/dots).
dots.lock is written next to the main dots.yaml.
Exit status is 1 if any warning or error was reported.
EOF
}

# ---------------------------------------------------------------- yaml parser
# Minimal parser for the nested "key: value" subset dots.yaml uses, plus
# "|" and ">" block scalars. Prints one line per scalar:
#   key US parent-path US value
# Newlines inside a value are encoded as RS so every scalar stays on one line.
yaml_parse() {
    local file=$1 line rest key val parent k indent i total
    local style chomp bl bind lind trail first text l prev explicit
    local -a ind=() keys=() lines=() blk=()
    local re_line='^([[:space:]]*)([^[:space:]].*)$'
    local re_key="^(\"[^\"]*\"|'[^']*'|[^:#[:space:]][^:#]*):([[:space:]]+(.*))?\$"
    local re_dq='^"(([^"\\]|\\.)*)"' re_sq="^'([^']*)'" re_block='^([|>])([-+]?)$'

    mapfile -t lines <"$file"
    total=${#lines[@]}
    for ((i = 0; i < total; i++)); do
        line=${lines[i]%$'\r'}
        [[ $line =~ ^[[:space:]]*(#.*)?$ ]] && continue
        [[ $line =~ $re_line ]]
        indent=${#BASH_REMATCH[1]}
        rest=${BASH_REMATCH[2]}
        if ! [[ $rest =~ $re_key ]]; then
            printf 'dots.sh: %s:%d: unsupported yaml: %s\n' "$file" "$((i + 1))" "$rest" >&2
            continue
        fi
        key=${BASH_REMATCH[1]}
        val=${BASH_REMATCH[3]}
        key=${key%"${key##*[![:space:]]}"}
        if [[ $key == \"*\" || $key == \'*\' ]]; then key=${key:1:${#key}-2}; fi

        explicit=0
        if [[ $val == \#* ]]; then
            val=
        elif [[ $val =~ $re_dq ]]; then
            explicit=1
            val=${BASH_REMATCH[1]}
            val=${val//\\\\/$'\x01'}
            val=${val//\\\"/\"}
            val=${val//\\n/$'\n'}
            val=${val//\\t/$'\t'}
            val=${val//$'\x01'/\\}
        elif [[ $val =~ $re_sq ]]; then
            explicit=1
            val=${BASH_REMATCH[1]}
        else
            val=${val%%[[:space:]]#*}
            val=${val%"${val##*[![:space:]]}"}
            if [[ $val =~ $re_block ]]; then
                explicit=1
                style=${BASH_REMATCH[1]} chomp=${BASH_REMATCH[2]}
                blk=() bind= trail=0
                while ((i + 1 < total)); do
                    bl=${lines[i + 1]%$'\r'}
                    if [[ $bl =~ ^[[:space:]]*$ ]]; then
                        blk+=("")
                    else
                        [[ $bl =~ $re_line ]]
                        lind=${#BASH_REMATCH[1]}
                        ((lind > indent)) || break
                        [[ -n $bind ]] || bind=$lind
                        ((lind >= bind)) || break
                        blk+=("${bl:bind}")
                    fi
                    i=$((i + 1))
                done
                while ((${#blk[@]} && ${#blk[-1]} == 0)); do
                    unset 'blk[-1]'
                    trail=$((trail + 1))
                done
                text= first=1 prev=1
                for l in "${blk[@]}"; do
                    if [[ $style == '>' ]]; then
                        if [[ -z $l ]]; then text+=$'\n'; prev=1
                        else
                            ((prev)) || text+=' '
                            text+=$l prev=0
                        fi
                    else
                        ((first)) || text+=$'\n'
                        text+=$l first=0
                    fi
                done
                case $chomp in
                    -) val=$text ;;
                    +) val=$text$'\n'; for ((k = 0; k < trail; k++)); do val+=$'\n'; done ;;
                    *) val=${text:+$text$'\n'} ;;
                esac
            fi
        fi

        while ((${#ind[@]} && ind[-1] >= indent)); do
            unset 'ind[-1]' 'keys[-1]'
        done
        parent=
        for k in "${keys[@]}"; do parent+=${parent:+/}$k; done
        ind+=("$indent")
        keys+=("$key")

        if [[ -n $val ]] || { ((explicit)) && [[ $key == content ]]; }; then
            printf '%s%s%s%s%s\n' "$key" "$US" "${parent:-.}" "$US" "${val//$'\n'/$RS}"
        fi
    done
}

# ------------------------------------------------------------------- helpers
expand_path() {
    local p=$1
    p=${p//\$\{HOME\}/$HOME}
    p=${p//\$HOME/$HOME}
    if [[ $p == "~" || $p == "~/"* ]]; then p=$HOME${p:1}; fi
    printf '%s' "$p"
}

remote_url() {
    local spec=$1
    case $spec in
        github:*)   spec=https://github.com/${spec#*:} ;;
        gitlab:*)   spec=https://gitlab.com/${spec#*:} ;;
        codeberg:*) spec=https://codeberg.org/${spec#*:} ;;
        *://* | git@*) ;;
        *) spec=$(expand_path "$spec") ;;
    esac
    case $spec in
        https://github.com/* | https://gitlab.com/* | https://codeberg.org/*)
            [[ $spec == *.git ]] || spec+=.git ;;
    esac
    printf '%s' "$spec"
}

# True if no names were given, or label equals / lives under one of them.
want_name() {
    local label=$1 n
    ((${#NAMES[@]})) || return 0
    for n in "${NAMES[@]}"; do
        n=${n%/}
        [[ $label == "$n" || $label == "$n"/* || ${label//\//-} == "$n" ]] && return 0
    done
    return 1
}

# ---------------------------------------------------------------------- lock
load_lock() {
    [[ -f $LOCK_FILE ]] || return 0
    local key name val
    while IFS=$US read -r key name val; do
        case $key in
            url)    LOCK_URL[$name]=$val ;;
            ref)    LOCK_REF[$name]=$val ;;
            commit) LOCK_COMMIT[$name]=$val ;;
        esac
    done < <(yaml_parse "$LOCK_FILE")
}

write_lock() {
    ((${#NEW_ORDER[@]})) || return 0
    local c out="# dots.lock - generated by dots.sh, do not edit"$'\n'
    for c in "${NEW_ORDER[@]}"; do
        out+=$(printf '"%s":\n    remote: "%s"\n    url: "%s"\n' "$c" "${NEW_SPEC[$c]}" "${NEW_URL[$c]}")$'\n'
        [[ -n ${NEW_REF[$c]} ]] && out+=$(printf '    ref: "%s"\n' "${NEW_REF[$c]}")$'\n'
        out+=$(printf '    commit: "%s"\n' "${NEW_COMMIT[$c]}")$'\n'
    done
    if [[ -f $LOCK_FILE && $(<"$LOCK_FILE") == "${out%$'\n'}" ]]; then return 0; fi
    printf '%s' "$out" >"$LOCK_FILE"
}

# -------------------------------------------------------------------- remotes
resolve_target() {
    local dir=$1 ref=$2 t
    if [[ -n $ref ]]; then
        for t in "origin/$ref" "$ref"; do
            git -C "$dir" rev-parse -q --verify "$t^{commit}" 2>/dev/null && return 0
        done
        return 1
    fi
    git -C "$dir" rev-parse -q --verify "origin/HEAD^{commit}" 2>/dev/null
}

checkout_commit() {
    local dir=$1 target=$2
    [[ $(git -C "$dir" rev-parse HEAD) == "$target" ]] ||
        git -C "$dir" checkout --quiet --detach "$target" 2>/dev/null
}

# Bring clone to the right commit. Returns 1 if the clone is unusable.
# A wanted update re-downloads into <dir>.new and swaps it in only on success.
# Sets SYNC_OLD (previous commit) and SYNC_CHANGED when a clone was (re)made.
sync_clone() {
    local label=$1 url=$2 ref=$3 dir=$4 locked=$5 target= redo=0 tmp verb=cloning new
    SYNC_OLD= SYNC_CHANGED=0
    command -v git >/dev/null || { err "$label: git not found"; return 1; }
    if [[ $MODE == update ]] && want_name "$label"; then redo=1; verb=re-downloading; fi

    if ((DRY)); then
        if [[ ! -d $dir/.git ]]; then info "would clone $label ($url)"; return 1; fi
        if ((redo)); then info "would re-download $label ($url)"; fi
        return 0
    fi

    if ((redo)) || [[ ! -d $dir/.git ]]; then
        SYNC_OLD=$(git -C "$dir" rev-parse HEAD 2>/dev/null || true)
        tmp=$dir.new
        mkdir -p -- "$DATA_DIR"
        rm -rf -- "$tmp"
        info "$verb $label ($url)"
        git clone --quiet -- "$url" "$tmp" || { rm -rf -- "$tmp"; err "$label: clone failed"; return 1; }
        if ((redo)) || [[ -z $locked && -n $ref ]]; then
            target=$(resolve_target "$tmp" "$ref") ||
                { rm -rf -- "$tmp"; err "$label: ref '${ref:-HEAD}' not found"; return 1; }
        else
            target=$locked
        fi
        if [[ -n $target ]] && ! checkout_commit "$tmp" "$target"; then
            rm -rf -- "$tmp"
            err "$label: cannot checkout ${target:0:12}"
            return 1
        fi
        rm -rf -- "$dir"
        mv -- "$tmp" "$dir"
        new=$(git -C "$dir" rev-parse HEAD)
        [[ $new == "$SYNC_OLD" ]] || SYNC_CHANGED=1
        if ((redo && SYNC_CHANGED && ${#SYNC_OLD})); then
            info "$label: ${SYNC_OLD:0:12} -> ${new:0:12}"
        elif ((redo)); then
            info "$label: ${new:0:12}${SYNC_OLD:+ (already up to date)}"
        fi
    elif [[ -n $locked ]]; then
        git -C "$dir" cat-file -e "$locked^{commit}" 2>/dev/null ||
            git -C "$dir" fetch --quiet --tags origin 2>/dev/null
        checkout_commit "$dir" "$locked" || { err "$label: cannot checkout ${locked:0:12} in $dir"; return 1; }
    fi
    return 0
}

run_post_update() {
    local label=$1 dir=$2 cmd=$3 old=$4 new=$5
    info "running post_update for $label: $cmd"
    (cd -- "$dir" && DOTS_NAME=$label DOTS_DIR=$dir DOTS_OLD_COMMIT=$old DOTS_COMMIT=$new bash -c "$cmd") ||
        err "$label: post_update failed"
}

remote_one() {
    local label=$1 spec=$2 ref=$3 post=$4 depth=$5
    local cname=${label//\//-} url dir locked= commit old changed
    url=$(remote_url "$spec")
    dir=$DATA_DIR/$cname

    if [[ ${LOCK_URL[$cname]:-} == "$url" && ${LOCK_REF[$cname]:-} == "$ref" ]]; then
        locked=${LOCK_COMMIT[$cname]:-}
    fi

    if [[ $MODE == update ]] && want_name "$label"; then N_MATCH=$((N_MATCH + 1)); fi

    case $MODE in
        link | update)
            sync_clone "$label" "$url" "$ref" "$dir" "$locked" || return
            old=$SYNC_OLD changed=$SYNC_CHANGED ;;
        unlink) [[ -f $dir/dots.yaml ]] || return 0 ;;
        *) [[ -d $dir/.git ]] || { warn "$label: remote not cloned (run: dots.sh link)"; return; } ;;
    esac

    commit=$(git -C "$dir" rev-parse HEAD)
    if [[ -z ${NEW_URL[$cname]:-} ]]; then NEW_ORDER+=("$cname"); fi
    NEW_SPEC[$cname]=$spec NEW_URL[$cname]=$url NEW_REF[$cname]=$ref NEW_COMMIT[$cname]=$commit

    if [[ $MODE == status ]]; then
        if [[ -z $locked ]]; then
            info "${C_DIM}remote $label @ ${commit:0:12} (not locked)${C_OFF}"
        elif [[ $locked != "$commit" ]]; then
            warn "remote $label @ ${commit:0:12}, lock says ${locked:0:12}"
        else
            info "${C_DIM}remote $label @ ${commit:0:12}${C_OFF}"
        fi
    fi

    if [[ ! -f $dir/dots.yaml ]]; then
        err "$label: no dots.yaml in remote repository"
        return
    fi
    process_file "$dir/dots.yaml" "$label" $((depth + 1))

    if [[ $MODE == update && -n $post ]] && want_name "$label"; then
        if ((DRY)); then
            info "would run post_update for $label: $post"
        elif ((changed)); then
            run_post_update "$label" "$dir" "$post" "$old" "$commit"
        fi
    fi
}

# ---------------------------------------------------------------------- links
link_one() {
    local label=$1 s=$2 d=$3 base=$4 virtual=${5:-0} state
    if [[ $MODE == unlink ]]; then
        want_name "$label" || return 0
        N_MATCH=$((N_MATCH + 1))
    fi
    s=$(expand_path "$s")
    d=$(expand_path "$d")
    [[ $s == /* ]] || s=$base/$s
    [[ $d == /* ]] || d=$base/$d
    s=$(realpath -ms -- "$s")
    d=$(realpath -ms -- "$d")

    if [[ -L $d ]]; then
        if [[ $(readlink -f -- "$d") == "$(readlink -f -- "$s")" ]]; then state=ok; else state=wrong; fi
    elif [[ -e $d ]]; then
        state=blocked
    else
        state=missing
    fi

    case $MODE:$state in
        unlink:ok)
            if ((DRY)); then info "would remove $d"; else rm -- "$d"; ok "$label: removed $d"; fi
            N_GONE=$((N_GONE + 1)) ;;
        unlink:*) ;;
        status:ok)      ok "$label: $d" ;;
        status:missing) info "${C_DIM}- $label: not linked ($d)${C_OFF}" ;;
        *:wrong)        warn "$label: $d is a symlink to $(readlink -- "$d"), expected $s" ;;
        *:blocked)      warn "$label: $d exists and is not a symlink" ;;
        status:*) ;;
        *:ok)           N_OK=$((N_OK + 1)) ;;
        *:missing)
            if ((! (DRY && virtual))) && [[ ! -e $s && ! -L $s ]]; then
                err "$label: source not found: $s"
                return
            fi
            if ((DRY)); then
                info "would link $d -> $s"
            else
                mkdir -p -- "$(dirname -- "$d")" && ln -s -- "$s" "$d" || { err "$label: cannot link $d"; return; }
                ok "$label: $d -> $s"
            fi
            N_NEW=$((N_NEW + 1)) ;;
    esac
}

# Mirror the tree under a package folder into a target folder, stow style:
# files are linked one by one, and a directory is linked as a whole ("folded")
# when nothing exists at its destination yet. Top-level directories (.config,
# .local, ...) are never folded, so they stay real directories.
stow_walk() {
    local label=$1 s=$2 d=$3 depth=$4 e name dd descend
    local -a entries=()
    mapfile -d '' -t entries < <(find "$s" -mindepth 1 -maxdepth 1 -print0 | sort -z)
    for e in "${entries[@]}"; do
        name=${e##*/}
        dd=$d/$name
        descend=0
        if [[ -d $e && ! -L $e ]]; then
            if [[ -d $dd && ! -L $dd ]]; then
                descend=1
            elif ((depth == 1)) && [[ ! -e $dd && ! -L $dd ]]; then
                descend=1
            fi
        fi
        if ((descend)); then
            stow_walk "$label/$name" "$e" "$dd" $((depth + 1))
        else
            link_one "$label/$name" "$e" "$dd" "$d"
        fi
    done
}

stow_entry() {
    local label=$1 s=$2 d=$3 base=$4
    s=$(expand_path "$s")
    d=$(expand_path "$d")
    [[ $s == /* ]] || s=$base/$s
    [[ $d == /* ]] || d=$base/$d
    s=$(realpath -ms -- "$s")
    d=$(realpath -ms -- "$d")
    if [[ ! -d $s ]]; then
        [[ $MODE == unlink ]] || err "$label: stow source is not a directory: $s"
        return
    fi
    stow_walk "$label" "$s" "$d" 1
}

# Write inline content to $DATA_DIR/.content/<label>, then link it like a source.
link_content() {
    local label=$1 content=$2 d=$3 base=$4 f cur
    if [[ $label == . || /$label/ == */../* ]]; then
        err "$label: content needs a plain entry name"
        return
    fi
    f=$DATA_DIR/.content/$label

    if [[ $MODE == link || $MODE == update ]]; then
        cur=
        [[ -f $f ]] && cur=$(cat -- "$f"; printf x)
        if [[ ! -f $f || ${cur%x} != "$content" ]]; then
            if ((DRY)); then
                info "would write content for $label ($f)"
            else
                mkdir -p -- "$(dirname -- "$f")" && printf '%s' "$content" >"$f" ||
                    { err "$label: cannot write $f"; return; }
                info "$label: wrote $f"
            fi
        fi
    fi
    link_one "$label" "$f" "$d" "$base" 1
}

# ---------------------------------------------------------------- dots.yaml
process_file() {
    local file=$1 prefix=$2 depth=$3 base key parent val p label sdir sdst
    local -A src=() dst=() rem=() ref=() post=() cont=() stow=() seen=()
    local -a order=()

    if ((depth > MAX_DEPTH)); then err "$file: remotes nested too deep"; return; fi
    base=$(cd -- "$(dirname -- "$file")" && pwd)

    while IFS=$US read -r key parent val; do
        case $key in
            source)      src["$parent"]=$val ;;
            destination) dst["$parent"]=$val ;;
            remote)      rem["$parent"]=$val ;;
            ref)         ref["$parent"]=$val ;;
            content)     cont["$parent"]=${val//$RS/$'\n'} ;;
            stow | use_stow)
                case ${val,,} in
                    true | yes | on) stow["$parent"]=1 ;;
                    false | no | off) ;;
                    *) err "$file: $key must be true or false, got '$val'" ;;
                esac ;;
            post_update | post-update) post["$parent"]=$val ;;
            *) continue ;;
        esac
        if [[ -z ${seen["$parent"]:-} ]]; then seen["$parent"]=1; order+=("$parent"); fi
    done < <(yaml_parse "$file")

    for p in "${order[@]}"; do
        if [[ $p == . ]]; then label=${prefix:-.}; else label=${prefix:+$prefix/}$p; fi

        if [[ -n ${rem["$p"]:-} ]]; then
            remote_one "$label" "${rem["$p"]}" "${ref["$p"]:-}" "${post["$p"]:-}" "$depth"
        fi
        if [[ -v cont["$p"] ]]; then
            if [[ -n ${src["$p"]:-} && $MODE != unlink ]]; then
                warn "$label: both source and content are set, using content"
            fi
            if [[ -n ${stow["$p"]:-} && $MODE != unlink ]]; then
                warn "$label: both stow and content are set, using content"
            fi
            if [[ -z ${dst["$p"]:-} ]]; then
                [[ $MODE == unlink ]] || err "$label: content needs a destination"
            else
                link_content "$label" "${cont["$p"]}" "${dst["$p"]}" "$base"
            fi
        elif [[ -n ${stow["$p"]:-} ]]; then
            if [[ $p == . ]]; then
                err "$label: stow needs a named entry"
            else
                sdir=${src["$p"]:-./${p##*/}} sdst=${dst["$p"]:-}
                [[ -n $sdst ]] || sdst='~'
                stow_entry "$label" "$sdir" "$sdst" "$base"
            fi
        elif [[ -n ${src["$p"]:-} || -n ${dst["$p"]:-} ]]; then
            if [[ -z ${src["$p"]:-} || -z ${dst["$p"]:-} ]]; then
                [[ $MODE == unlink ]] || err "$label: needs both source and destination"
            else
                link_one "$label" "${src["$p"]}" "${dst["$p"]}" "$base"
            fi
        fi
    done
}

# ----------------------------------------------------------------------- main
main() {
    local cmd= optcmd=
    while (($#)); do
        case $1 in
            -h | --help)    usage; exit 0 ;;
            -V | --version) echo "dots.sh $VERSION"; exit 0 ;;
            -c | --config)  [[ $# -ge 2 ]] || die "$1 needs a file"; CONFIG=$2; shift 2 ;;
            -n | --dry-run) DRY=1; shift ;;
            -u | --undo | --update)
                [[ $# -ge 2 ]] || die "$1 needs a name"
                local want=unlink; [[ $1 == --update ]] && want=update
                [[ -z $optcmd || $optcmd == "$want" ]] || die "--undo and --update cannot be combined"
                optcmd=$want; NAMES+=("$2"); shift 2 ;;
            -*)             die "unknown option: $1" ;;
            *)              if [[ -z $cmd ]]; then cmd=$1; else NAMES+=("$1"); fi; shift ;;
        esac
    done

    if [[ -n $optcmd ]]; then
        [[ -z $cmd || $cmd == "$optcmd" ]] || die "--undo/--update cannot be combined with '$cmd'"
        cmd=$optcmd
    fi
    case ${cmd:-link} in
        link | sync) MODE=link ;;
        update | status | unlink) MODE=$cmd ;;
        *) die "unknown command: $cmd (try --help)" ;;
    esac
    if ((${#NAMES[@]})) && [[ $MODE != update && $MODE != unlink ]]; then
        die "only 'update' and 'unlink' take names"
    fi

    [[ -f $CONFIG ]] || die "config not found: $CONFIG"
    CONFIG=$(realpath -- "$CONFIG")
    LOCK_FILE=$(dirname -- "$CONFIG")/dots.lock

    load_lock
    process_file "$CONFIG" "" 0
    if [[ $MODE == update ]] && ((${#NAMES[@]} && N_MATCH == 0)); then
        err "no remote matches: ${NAMES[*]}"
    fi
    if [[ $MODE == link || $MODE == update ]] && ((! DRY)); then write_lock; fi

    case $MODE in
        status) ;;
        unlink)
            if ((${#NAMES[@]} && N_MATCH == 0)); then err "no entry matches: ${NAMES[*]}"; fi
            info "$N_GONE removed, $N_WARN warnings, $N_ERR errors" ;;
        *)      info "$N_NEW linked, $N_OK up to date, $N_WARN warnings, $N_ERR errors" ;;
    esac
    ((N_WARN == 0 && N_ERR == 0))
}

main "$@"
