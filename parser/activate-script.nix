{ pkgs, lib, ... }:
{
  username,
  managedPathsFile,
  fileCommands ? [ ],
  shell-rc,
  home,
  gen-dir,
  profile-dir,
  shell-rc-path-command,
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

    mkdir -p "${home}" "${gen-dir}"

    PREV_GEN_PATH=""
    if [ -L "${gen-dir}/current" ]; then
      PREV_GEN_PATH="$(readlink -f "${gen-dir}/current")"
    fi

    ensure_path_in_shell_rc() {
      rc_file="$1"
      [ -f "$rc_file" ] || touch "$rc_file"

      # shellcheck disable=SC2016
      if ! grep -Fq '${shell-rc-path-command}' "$rc_file"; then
        # shellcheck disable=SC2016
        echo '${shell-rc-path-command}' >> "$rc_file"
      fi
    }

    ensure_path_in_shell_rc "${shell-rc}"

    if [ -n "$PREV_GEN_PATH" ] && [ -f "$PREV_GEN_PATH/managed-paths" ]; then
      while IFS= read -r relPath || [ -n "$relPath" ]; do
        if ! grep -Fxq "$relPath" "${managedPathsFile}"; then
          case "$relPath" in
            "${home}"/*) rm -rf "$relPath" ;;
            *) echo "Refusing to remove non-home managed path: $relPath" >&2 ;;
          esac
        fi
      done < "$PREV_GEN_PATH/managed-paths"
    fi

    ${builtins.concatStringsSep "\n\n" fileCommands}
  '';
}
