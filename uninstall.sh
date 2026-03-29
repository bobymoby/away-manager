#!/usr/bin/env bash

set -euo pipefail

nix build
./result/bin/away-manager-uninstall
if [[ ${1:-} == "--force" ]]; then
  rm -rf ~/.away-manager
  rm -rf ~/.away-manager-profile
fi