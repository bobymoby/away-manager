#!/usr/bin/env bash

set -euo pipefail

prog="$(basename "${0}")"

usage() {
  cat <<EOF
${prog} - build + apply an away-manager configuration

Usage:
  ${prog} <switch|uninstall> --flake <flake-ref>
  ${prog} <switch|uninstall> --flake <flake-ref> --dry

Examples:
  ${prog} switch --flake '.#default'
  ${prog} switch --flake '.#bobymoby'
  ${prog} uninstall --flake '.#bobymoby'
  ${prog} switch --flake '.#bobymoby' --dry

Notes:
  - <flake-ref> should resolve to an away-manager package output that contains:
      bin/away-manager-activate
      bin/away-manager-uninstall
  - --dry prints the commands that would be executed, without executing them.
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
dryRun=0

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
    --dry)
      dryRun=1
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

out_path="$(nix build --no-link --print-out-paths "$flake")"

if ((dryRun)); then
  case "$cmd" in
    switch)
      cat "$out_path/bin/away-manager-activate" | "$PAGER"
      ;;
    uninstall)
      cat "$out_path/bin/away-manager-uninstall" | "$PAGER"
      ;;
  esac
  exit 0
fi

[[ -n "$out_path" ]] || die "failed to build flake ref: $flake"

case "$cmd" in
  switch)
    exec "$out_path/bin/away-manager-activate"
    ;;
  uninstall)
    exec "$out_path/bin/away-manager-uninstall"
    ;;
esac