#!/usr/bin/env bash

set -euo pipefail

nix build
./result/bin/away-manager-activate