{ pkgs, lib, ... }:
{
  username,
  gen-dir,
  profile-dir,
}:
pkgs.writeShellApplication {
  name = "away-manager-uninstall";
  runtimeInputs = with pkgs; [
    coreutils
    findutils
    gnugrep
  ];

  text = ''
    set -euo pipefail

    CURRENT_GEN_PATH=""

    if [ -L "${gen-dir}/current" ]; then
      CURRENT_GEN_PATH="$(readlink -f "${gen-dir}/current")"
    fi

    if [ -n "$CURRENT_GEN_PATH" ] && [ -f "$CURRENT_GEN_PATH/managed-paths" ]; then
      while IFS= read -r relPath || [ -n "$relPath" ]; do
        rm -rf "$relPath"
      done < "$CURRENT_GEN_PATH/managed-paths"
    fi

    rm -f "${profile-dir}"
    rm -f "${gen-dir}/current"
    rm -rf "${gen-dir}"
  '';
}
