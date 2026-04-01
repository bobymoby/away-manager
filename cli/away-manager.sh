#!/usr/bin/env bash

set -euo pipefail

prog="$(basename "${0}")"

usage() {
  cat <<EOF
${prog} - build + apply an away-manager configuration

Usage:
  ${prog} <switch|uninstall> --flake <flake-ref>

Examples:
  ${prog} switch --flake '.#default'
  ${prog} switch --flake '.#bobymoby'
  ${prog} uninstall --flake '.#bobymoby'

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
    switch|uninstall)
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

[[ -n "$cmd" ]] || die "missing command (expected 'switch' or 'uninstall')"
[[ -n "$flake" ]] || die "missing --flake <flake-ref>"

case "$cmd" in
  switch)
    GEN_DIR="$HOME/.away-manager"
    GEN_PATH="$GEN_DIR/gen-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$GEN_DIR"
    nix build "$flake" --out-link "$GEN_PATH"
    "$GEN_PATH/bin/away-manager-activate"
    ln -sfn "$GEN_PATH" "$GEN_DIR/current"
    ln -sfn "$GEN_DIR/current/packages" "$HOME/.away-manager-profile"
    ;;
  uninstall)
    exec "$(nix build --no-link --print-out-paths "$flake")/bin/away-manager-uninstall"
    ;;
esac