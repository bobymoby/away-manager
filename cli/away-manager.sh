#!/usr/bin/env bash

set -euo pipefail

prog="$(basename "${0}")"

usage() {
  cat <<EOF
${prog} - build + apply an away-manager configuration

Usage:
  ${prog} switch --flake <flake-ref>
  ${prog} uninstall --flake <flake-ref>
  ${prog} clean

Examples:
  ${prog} switch --flake '.#default'
  ${prog} switch --flake '.#bobymoby'
  ${prog} uninstall --flake '.#bobymoby'
  ${prog} clean

Notes:
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

cmd=""
flake=""
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
    switch|uninstall|clean)
      if [[ -n "$cmd" ]]; then
        die "multiple commands specified: '$cmd' and '$1'"
      fi
      cmd="$1"
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

[[ -n "$cmd" ]] || die "missing command (expected 'switch', 'uninstall', or 'clean')"

case "$cmd" in
  switch)
    [[ -n "$flake" ]] || die "missing --flake <flake-ref>"
    ;;
  clean)
    if [[ -n "${flake:-}" ]]; then
      die "'clean' does not take --flake"
    fi
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

EVALUATION_RESULT=$(nix eval --json --no-pretty "$flake.config.away" --apply 'cfg: { inherit (cfg) home gen-dir; }')
HOME_DIR=$(jq -r '.home' <<< "$EVALUATION_RESULT")
GEN_DIR=$(jq -r '."gen-dir"' <<< "$EVALUATION_RESULT")

case "$cmd" in
  switch)
    GEN_PATH="$GEN_DIR/gen-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$GEN_DIR"
    nix build "$flake.activationPackage" --out-link "$GEN_PATH" "${show_trace:+--show-trace}"
    "$GEN_PATH/bin/away-manager-activate"
    ln -sfn "$GEN_PATH" "$GEN_DIR/current"
    ln -sfn "$GEN_DIR/current/packages" "$HOME_DIR/.away-manager-profile"
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