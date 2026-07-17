#!/usr/bin/env bash

# A.sh is a simple bash scripts for seamless developer interaction
# with different languages.

set -euo pipefail

ASH_VERSION="0.0.1"

function log() { 1>&2 echo "$@"; }

REQUIRED_PROGRAMS=(
  git=https://git-scm.com/
  jq=https://jqlang.org/
  go-toml=https://github.com/pelletier/go-toml
  enry=https://pkg.go.dev/github.com/go-enry/go-enry/
)

function usage() {
  log "Usage: $0 [-hdg] [-c config] CMD ..."
  log
  log " where CMD is one of"
  log
  cmd-list | awk '{ print " ", $0}' 2>&1
  log
  log " with options:"
  log
  log "  -h            display this help message."
  log "  -d            enable debug mode."
  log "  -g            always use global configurations, even when in a repo."
  log "  -c config     only use this config (overrides ASH_SINGLETON_CONFIG)"

  exit 1
}

# COMMANDS

doc_checkhealth="check the health of a.sh"
function cmd-checkhealth() {
  local missing=()

  for program in "${REQUIRED_PROGRAMS[@]}"; do
    IFS="=" read -a args <<<"$program"
    if ! command -v "${args[0]}" >/dev/null 2>&1; then
      missing+=("$program")
    fi
  done

  if [ "${#missing[@]}" -ne 0 ]; then
    log "Error: The following required programs are not installed:"
    for program in "${missing[@]}"; do
      IFS="=" read -a args <<<"$program"
      echo "  - ${args[0]} see instructions at ${args[1]}"
    done
    log
    log "Please install them and re-run this script."
    return 1
  fi

  log "All required programs are installed."
}

doc_language="try to guess the language of a file"
function cmd-language() {
  function usage() {
    log "Usage: $0 language [-h] ARGS..."
    log
    log " Outputs the language of each ARGS, if ARGS is empty, read from stdin."
    log
    log "  -h            Display this help"
    exit 1
  }
  OPTIND=0
  while getopts "h" o; do
    case "$o" in
    *) usage ;;
    esac
  done

  shift $((OPTIND - 1))
  OPTIND=0

  local ARGS=("$@")
  if [ ${#ARGS[@]} -eq 0 ]; then
    mapfile -t ARGS
  fi

  function gitattribute_source() {
    local GIT_ATTRS=(linguist-language language)
    git check-attr "${GIT_ATTRS[@]}" -- "$arg" 2>/dev/null |
      awk -F': ' '
        $3 != "unset" && $3 != "unspecified" { print $3 }
      ' |
      sed "s/-/ /g"
  }

  function enry_source() {
    enry "$arg" | sed -n -E 's/ *language: *([^ ]{1,})/\1/p'
  }

  function fallback_source() {
    awk -v name="$(basename $arg)" -v ext="*.${arg##*.}" -F'\t' '
      $1 == name || $1 == ext { print $2 }
    ' "$ASH_DIR/share/linguist.tsv"
  }

  for arg in "${ARGS[@]}"; do
    for src in gitattribute_source enry_source fallback_source; do
      debug "trying ${src}"
      if mapfile -t language < <($src | sort -u) &&
        [ ${#language[@]} -ne 0 ]; then
        break
      fi
    done
    if [ ${#language[@]} -ne 1 ]; then
      log "Error: could not find a single language for $file"
      log "You can specify it in the .gitattributes file"
      log "  $arg linguist-language=Your-Crazy-Lang"
      for lang in "${language[@]}"; do
        log "  $arg linguist-language=${lang// /-}"
      done
      return 1
    fi
    echo "${language}"
  done

}

doc_config="get the configuration of a language (or file)"
function cmd-config() {

  function usage() {
    log "Usage: $0 config [-ehcr] [target] QUERY"
    log
    log " Outputs QUERY on the config files"
    log
    log "  -e            Return after first hit"
    log "  -h            Display this help"
    log
    log " where target is one of: "
    log
    log "  -f file       Run query on file"
    log "  -l language   Run query on language"
    log "  -F formatter  Run query on formatter"
    log "  -S server     Run query on server"
    log "  -a            Run query on all of the config"
    log
    log
    log " Options passed on to jq, "
    log
    log "  -c            Compact representation of jq"
    log "  -r            Get the raw output, null separated"
    exit 1
  }

  local target="all"
  local arg=""
  local jq_args=()
  local only_language=0
  local early_return=0
  while getopts "ehacrl:f:F:S:" o; do
    case "$o" in
    h) usage ;;
    f)
      target="language"
      arg=$(cmd-language "${OPTARG}")
      ;;
    l)
      target="language"
      arg="${OPTARG}"
      ;;
    F)
      target="formatter"
      arg="${OPTARG}"
      ;;
    S)
      target="server"
      arg="${OPTARG}"
      ;;
    a) target="all" ;;
    e) early_return=1 ;;
    r) jq_args+=("--raw-output0") ;;
    c) jq_args+=("--compact-output") ;;
    \?) usage ;;
    esac
  done

  shift $((OPTIND - 1))
  OPTIND=0

  local QUERY="${1:-}"

  if ! shift 1; then
    log "Error: expected an argument QUERY"
    log
    usage
  fi

  case "${target}" in
  language)
    jq_args+=(--arg lang "${arg}")
    QUERY=".languages[\$lang] | $QUERY"
    ;;
  formatter)
    jq_args+=(--arg formatter "${arg}")
    QUERY=".formatters[\$formatter] | $QUERY"
    ;;
  server)
    jq_args+=(--arg server "${arg}")
    QUERY=".servers[\$server] | $QUERY"
    ;;
  all) ;;
  *) log "unexpected" ;;
  esac

  for cfg in "${ASH_CONFIGS[@]}"; do
    debug "looking up in $cfg"

    local exit_code=0
    if [ "${cfg##*.}" == "toml" ]; then
      tomljson "$cfg"
    else
      cat "$cfg"
    fi | jq -e "${jq_args[@]}" "$QUERY" || exit_code=$?
    if ((early_return)) && [ $exit_code -ne 4 ]; then
      debug "found solution, breaking"
      break
    fi
  done
}

doc_fmt_find="get formatter for a language"
function cmd-fmt-find() {
  function usage() {
    log "Usage: $0 fmt-find [-hcx] [-f file | -l language] "
    log
    log " -l language  the name of the language to find a formatter for."
    log " -f file      the name of the file to find a formatter for."
    log " -x           require a formatter to exist"
    log " -c           check the version with '--version'."
    log " -h           display this help message."
    exit 1
  }

  local file=""
  local language=""
  local check=0
  local strict=0
  while getopts "xhcf:l:" opt; do
    case "$opt" in
    h) usage ;;
    f) file="$OPTARG" ;;
    l) language="$OPTARG" ;;
    x) strict=1 ;;
    c) check=1 ;;
    \?)
      echo "Invalid option: -$OPTARG"
      usage
      ;;
    esac
  done

  shift $((OPTIND - 1))
  OPTIND=0

  if [ -n "${file:-}" ]; then
    if git check-attr "format" -- "$file" 2>/dev/null | grep -q 'unset'; then
      debug "file ${file} ignored"
      return 3
    fi
  fi

  if [ -z "${language:-}" ]; then
    if [ -z "${file:-}" ]; then
      log "Error: expected either -f file or -l language"
      usage
    fi
    language=$(cmd-language "$file")
  fi

  mapfile -d '' formatter < <(cmd-config -rcF "$language" '(if . then .[] else (null,[]) end)')

  if [[ ${#formatter[@]} == 0 ]]; then
    debug "formatter ${file} ignored"
    return 3
  fi

  if [ "${formatter[0]}" == "null" ]; then
    debug "Found null formatter for $language, ignoring it"
    return 2
  fi

  debug "Found formatter:"
  debug "  ${formatter[@]}"

  if ((check)); then
    debug "with version: $(${formatter[0]} --version)"
  fi

  printf '%q ' "${formatter[@]}"
}

doc_fmt_io="run the formatter in IO mode"
function cmd-fmt-io() {
  function usage() {
    log "Usage: $0 fmt-io [-h] [ -l LANGUAGE | -f FILE ]"
    log
    log "  Run formatter in IO mode for language"
    log "  or guess the language from the file"
    exit 1
  }

  local opts=()
  while getopts "hl:f:" opt; do
    case "$opt" in
    h) usage ;;
    l) opts+=(-l "$OPTARG") ;;
    f) opts+=(-f "$OPTARG") ;;
    \?)
      echo "Invalid option: -$OPTARG"
      usage
      ;;
    esac
  done

  shift $((OPTIND - 1))
  OPTIND=0

  if [ ${#opts[@]} -eq 0 ]; then
    log "Error: expected either -f file or -l language"
    usage
  fi

  $(cmd-fmt-find -x "${opts[@]}")

}

doc_list="print a list of commands"
function cmd-list() {
  declare -F | sed -n 's/.*cmd-//p' | while read -r cmd; do
    local doc=$(eval "echo \"\${doc_${cmd//-/_}:-??}\"")
    printf "%-17s%s\n" "$cmd" "$doc"
  done

}

doc_fmt="run the formatter on a list of file"
function cmd-fmt() {

  function usage() {
    log "Usage: $0 fmt [-hcwD] FILE..."
    log
    log "  format FILEs, if no file is given, the files are read from"
    log "  stdin."
    log
    log "  -w      override the file"
    log "  -c      check the file for formatting (default)"
    log
    exit 1
  }

  local mode=check
  local print_diff=0
  while getopts "hcwD" opt; do
    case "$opt" in
    h) usage ;;
    c) mode=check ;;
    w) mode=write ;;
    \?)
      echo "Invalid option: -$OPTARG"
      usage
      ;;
    esac
  done

  shift $((OPTIND - 1))
  OPTIND=0

  local ARGS=("$@")
  if [[ ${#ARGS[@]} -eq 0 ]]; then
    mapfile -t ARGS
  fi

  local fmt_folder=".cache/ash/fmt"
  mkdir -p "$fmt_folder"
  echo "**/*" >".cache/ash/.gitignore"

  local fmt_file=$(mktemp -p "$fmt_folder")
  local fmt_patch=".cache/ash/patch"

  echo "" >"$fmt_file"
  rm -f "$fmt_patch"

  for file in "${ARGS[@]}"; do

    local result=0
    formatter=$(cmd-fmt-find -f "$file") || result=$?
    if [ $result == 3 ]; then
      continue
    fi

    1>&2 printf '%-50s' "$file"
    if ((result)); then
      if [ $result == 2 ]; then
        local language=$(cmd-language "$file")
        1>&2 printf '%30s\n' "no fmt [$language]"
        continue
      fi
      return $result
    fi

    local formatter=($formatter)

    debug "writing to ${fmt_file}"
    local result=0
    "${formatter[@]}" <"$file" >"${fmt_file}" || result=$?

    if ((result)); then
      log "Error: got non-zero exit-code: $result"
      1>&2 printf '%30s\n' "error ($result)"
      return "$result"
    fi

    if 1>/dev/null diff -q ${file} ${fmt_file}; then
      1>&2 printf '%30s\n' "unchanged"
      continue
    fi

    1>&2 printf '%30s\n' "changed"

    diff -u "$file" --label "$file" --label "$file" "$fmt_file" >>"$fmt_patch" || true
  done

  rm -rf "${fmt_file}"

  if [[ ! -e $fmt_patch ]]; then
    log "no changes"
    return 0
  fi

  case "$mode" in
  check)
    log "accept using: patch -p0 < $fmt_patch"
    return 1
    ;;
  write)
    patch -p0 <"$fmt_patch"
    ;;
  esac
}

function debug() { return 0; }

safe_mode=1
while getopts "hdgc:" opt; do
  case "$opt" in
  h) usage ;;
  d) function debug() { 1>&2 echo "[debug]" "$@"; } ;;
  c) ASH_SINGLETON_CONFIG="${OPTARG}" ;;
  g) safe_mode=0 ;;
  \?)
    log "Error: invalid option: -$OPTARG"
    log
    usage
    ;;
  esac
done

shift $((OPTIND - 1))
OPTIND=0

function find_prj_root() {
  local old_pwd=""
  while [[ $old_pwd != "$PWD" ]]; do
    if [[ -d .config ]]; then
      echo "$PWD"
      return 0
    fi
    old_pwd=$PWD
    cd ..
    if [[ $old_pwd == "$PWD" ]]; then
      log "ERROR: could not find project root"
      return 1
    fi
  done
}

: "${PRJ_ROOT:=$(find_prj_root)}"
: "${PRJ_ROOT:=$(git rev-parse --show-toplevel 2>/dev/null)}"

if [ -z "$PRJ_ROOT" ]; then
  debug "Could not find git root directory"
else
  debug "Found project root: $PRJ_ROOT"
fi

if [ -z ${ASH_DIR:-} ]; then
  export ASH_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && cd .. && pwd -P)"
fi

function config-find() {
  local configs=()
  local missing=()
  if [ -n "${ASH_SINGLETON_CONFIG:-}" ]; then
    if [ -e "$ASH_SINGLETON_CONFIG" ]; then
      configs=("$ASH_SINGLETON_CONFIG")
    else
      missing+=("$ASH_SINGLETON_CONFIG")
    fi
  else

    local CONFIGS_DIRS=("${PRJ_ROOT:-.}/.config")

    if ! ((safe_mode)) || [ -z "${PRJ_ROOT:-}" ]; then
      CONFIGS_DIRS+=(
        "${XDG_CONFIG_DIRS:-$HOME/.config}"
        "$HOME"
        "$ASH_DIR/share"
      )
    fi

    for dir in "${CONFIGS_DIRS[@]}"; do
      for file in "ash.json" "ash.toml"; do
        if [ -e "$dir/$file" ]; then
          configs+=("$dir/$file")
        else
          missing+=("$dir/$file")
        fi
      done
    done
  fi

  if [ ${#configs[@]} -eq 0 ]; then
    log "Error: found no configurations, looked in:"
    for missing in "${missing[@]}"; do
      log " - ${missing}"
    done
    exit 1
  else
    debug "Found configs:"
    for config in "${configs[@]}"; do
      debug " - $config"
    done
  fi

  printf '%q ' "${configs[@]}"
}

ASH_CONFIGS=($(config-find))
CMD="${1:-}"

if shift 1; then
  "cmd-$CMD" "$@"
else
  log "missing CMD"
  usage
fi
