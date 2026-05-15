#!/usr/bin/env bash

set -euo pipefail

prog="$(basename "${0}")"

usage() {
  cat <<EOF
${prog} - build + apply an away-manager configuration

Usage:
  ${prog} switch --flake <flake-ref>
  ${prog} list [--flake <flake-ref>]
  ${prog} activate --generation <gen-name> [--flake <flake-ref>]
  ${prog} uninstall [--flake <flake-ref>]
  ${prog} clean [--flake <flake-ref>]

Examples:
  ${prog} switch --flake '.#default'
  ${prog} list
  ${prog} activate --generation gen-20250516-120000
  ${prog} activate --flake '.#bobymoby' --generation gen-20250516-120000
  ${prog} clean

Notes:
  - Without --flake, list/activate/clean use \$HOME and \$HOME/.away-manager.
  - <flake-ref> should resolve to an away-manager package output that contains:
      bin/away-manager-activate
      bin/away-manager-uninstall
EOF
}

die() {
  echo "error: $*" >&2
  echo >&2
  usage >&2
  exit 2
}

collect_generations() {
  local gen_dir="$1"
  generations=()
  while IFS= read -r -d '' g; do
    generations+=("$g")
  done < <(find "$gen_dir" -maxdepth 1 -name 'gen-*' -print0 2>/dev/null | sort -z)
}

resolve_generation() {
  local gen_dir="$1" spec="$2"
  local g base

  collect_generations "$gen_dir"
  ((${#generations[@]})) || die "no generations found in '$gen_dir'"

  for g in "${generations[@]}"; do
    base="$(basename "$g")"
    if [[ "$base" == "$spec" ]]; then
      echo "$g"
      return
    fi
  done

  die "no generation named '$spec'"
}

list_generations() {
  local gen_dir="$1"
  local current_target="" g base marker

  if [[ -L "$gen_dir/current" ]]; then
    current_target="$(readlink -f "$gen_dir/current" 2>/dev/null || true)"
  fi

  collect_generations "$gen_dir"
  ((${#generations[@]})) || {
    echo "no generations in '$gen_dir'"
    return
  }

  for g in "${generations[@]}"; do
    base="$(basename "$g")"
    marker=""
    if [[ -n "$current_target" && "$g" == "$current_target" ]]; then
      marker=" (current)"
    fi
    printf '%s%s\n' "$base" "$marker"
  done
}

activate_generation() {
  local gen_path="$1" gen_dir="$2" home_dir="$3"
  [[ -x "$gen_path/bin/away-manager-activate" ]] \
    || die "generation '$gen_path' is missing away-manager-activate"
  "$gen_path/bin/away-manager-activate"
  ln -sfn "$gen_path" "$gen_dir/current"
  ln -sfn "$gen_dir/current/packages" "$home_dir/.away-manager-profile"
}

resolve_away_paths() {
  if [[ -n "$flake" ]]; then
    local evaluation_result
    evaluation_result=$(nix eval --json --no-pretty "$flake.config.away" --apply 'cfg: { inherit (cfg) home gen-dir; }')
    HOME_DIR=$(jq -r '.home' <<< "$evaluation_result")
    GEN_DIR=$(jq -r '."gen-dir"' <<< "$evaluation_result")
  else
    HOME_DIR="$HOME"
    GEN_DIR="$HOME/.away-manager"
  fi
}

cmd=""
flake=""
generation=""
show_trace=0

if (($# == 0)); then
  usage
  exit 0
fi

while (($#)); do
  case "$1" in
    -h|--help)
      usage
      exit 0
      ;;
    --show-trace)
      show_trace=1
      shift
      ;;
    switch|uninstall|clean|list|activate)
      if [[ -n "$cmd" ]]; then
        die "multiple commands specified: '$cmd' and '$1'"
      fi
      cmd="$1"
      shift
      ;;
    --generation)
      shift
      [[ $# -gt 0 ]] || die "--generation requires a value"
      generation="$1"
      shift
      ;;
    --generation=*)
      generation="${1#--generation=}"
      shift
      ;;
    --flake)
      shift
      [[ $# -gt 0 ]] || die "--flake requires a value"
      flake="$1"
      shift
      ;;
    --flake=*)
      flake="${1#--flake=}"
      shift
      ;;
    --)
      shift
      break
      ;;
    *)
      die "unexpected argument: '$1'"
      ;;
  esac
done

[[ -n "$cmd" ]] || die "missing command (expected 'switch', 'list', 'activate', 'uninstall', or 'clean')"

case "$cmd" in
  switch)
    [[ -n "$flake" ]] || die "missing --flake <flake-ref>"
    ;;
  activate)
    [[ -n "$generation" ]] || die "missing --generation <gen-name>"
    ;;
  uninstall)
    if [[ -f "$HOME/.away-manager/current/bin/away-manager-uninstall" ]]; then
      exec "$HOME/.away-manager/current/bin/away-manager-uninstall"
    else
      # echo "warning: no current away-manager profile found at '$HOME/.away-manager/current', skipping uninstall script" >&2
      echo "rebuilding"
      exec "$(nix build --no-link --print-out-paths "${show_trace:+--show-trace}" "$flake.activationPackage")/bin/away-manager-uninstall"
    fi
esac

case "$cmd" in
  switch|list|activate|clean)
    resolve_away_paths
    ;;
esac

case "$cmd" in
  switch)
    GEN_PATH="$GEN_DIR/gen-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$GEN_DIR"
    nix build "$flake.activationPackage" --out-link "$GEN_PATH" "${show_trace:+--show-trace}"
    activate_generation "$GEN_PATH" "$GEN_DIR" "$HOME_DIR"
    ;;
  list)
    list_generations "$GEN_DIR"
    ;;
  activate)
    GEN_PATH="$(resolve_generation "$GEN_DIR" "$generation")"
    activate_generation "$GEN_PATH" "$GEN_DIR" "$HOME_DIR"
    ;;
  uninstall)
    # exec "$(nix build --no-link --print-out-paths "${show_trace:+--show-trace}" "$flake.activationPackage")/bin/away-manager-uninstall"
    ;;
  clean)
    if [[ ! -d "$GEN_DIR" ]]; then
      exit 0
    fi

    current_target=""
    if [[ -L "$GEN_DIR/current" ]]; then
      current_target="$(readlink "$GEN_DIR/current" || true)"
      if [[ "$current_target" != /* ]]; then
        current_target="$GEN_DIR/$current_target"
      fi
    fi

    while IFS= read -r -d '' g; do
      if [[ -n "$current_target" && "$g" == "$current_target" ]]; then
        continue
      fi
      rm -rf -- "$g"
    done < <(find "$GEN_DIR" -maxdepth 1 -name 'gen-*' -print0)
    ;;
esac