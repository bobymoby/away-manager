{ pkgs, lib, ... }:
{ username }:
pkgs.writeShellApplication {
  name = "away-manager-uninstall";
  runtimeInputs = with pkgs; [
    coreutils
    findutils
    gnugrep
  ];

  text = ''
    set -euo pipefail

    HOME_DIR="/home/${username}"
    GEN_DIR="$HOME_DIR/.away-manager"
    CURRENT_GEN_PATH=""

    if [ -L "$GEN_DIR/current" ]; then
      CURRENT_GEN_PATH="$(readlink -f "$GEN_DIR/current")"
    fi

    if [ -n "$CURRENT_GEN_PATH" ] && [ -f "$CURRENT_GEN_PATH/managed-paths" ]; then
      while IFS= read -r relPath || [ -n "$relPath" ]; do
        rm -rf "$relPath"
      done < "$CURRENT_GEN_PATH/managed-paths"
    fi

    rm -f "$HOME_DIR/.away-manager-profile"
    rm -f "$GEN_DIR/current"
    rm -rf "$GEN_DIR"
  '';
}
