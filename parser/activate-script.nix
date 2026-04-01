{ pkgs, lib, ... }:
{
  username,
  managedPathsFile,
  fileCommands ? [ ],
}:
pkgs.writeShellApplication {
  name = "away-manager-activate";
  runtimeInputs = with pkgs; [
    coreutils
    findutils
    gnugrep
  ];

  text = ''
    set -euo pipefail

    HOME_DIR="/home/${username}"
    GEN_DIR="$HOME_DIR/.away-manager"
    MANAGED_PATHS_STORE_FILE="${managedPathsFile}"

    mkdir -p "$HOME_DIR" "$GEN_DIR"

    PREV_GEN_PATH=""
    if [ -L "$GEN_DIR/current" ]; then
      PREV_GEN_PATH="$(readlink -f "$GEN_DIR/current")"
    fi

    ensure_path_in_shell_rc() {
      rc_file="$1"
      [ -f "$rc_file" ] || touch "$rc_file"

      # shellcheck disable=SC2016
      if ! grep -Fq 'export PATH="$HOME/.away-manager-profile/bin:$PATH"' "$rc_file"; then
        # shellcheck disable=SC2016
        echo 'export PATH="$HOME/.away-manager-profile/bin:$PATH"' >> "$rc_file"
      fi
    }

    ensure_path_in_shell_rc "$HOME_DIR/.bashrc"

    if [ -n "$PREV_GEN_PATH" ] && [ -f "$PREV_GEN_PATH/managed-paths" ]; then
      while IFS= read -r relPath || [ -n "$relPath" ]; do
        if ! grep -Fxq "$relPath" "$MANAGED_PATHS_STORE_FILE"; then
          case "$relPath" in
            "$HOME_DIR"/*) rm -rf "$relPath" ;;
            *) echo "Refusing to remove non-home managed path: $relPath" >&2 ;;
          esac
        fi
      done < "$PREV_GEN_PATH/managed-paths"
    fi

    ${builtins.concatStringsSep "\n\n" fileCommands}
  '';
}
