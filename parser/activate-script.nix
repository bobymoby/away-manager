{ pkgs, lib, ... }:
{
  username,
  managedPathsFile,
  fileCommands ? [ ],
  shell-rc,
  home,
  gen-dir,
  profile-dir,
  script-extensions,
}:
let
  sourceCommand = ''. "${gen-dir}/current/away-manager-source-rc.sh"'';
  beforeActivationCommands = lib.am.concatStringsNewLine script-extensions.beforeActivation;
  afterActivationCommands = lib.am.concatStringsNewLine script-extensions.afterActivation;
in
pkgs.writeShellApplication {
  name = "away-manager-activate";

  runtimeInputs = with pkgs; [
    coreutils
    findutils
    gnugrep
  ];

  text = ''
    set -euo pipefail

    ${beforeActivationCommands}

    mkdir -p "${home}" "${gen-dir}"

    PREV_GEN_PATH=""
    if [ -L "${gen-dir}/current" ]; then
      PREV_GEN_PATH="$(readlink -f "${gen-dir}/current")"
    fi

    [ -f "${shell-rc}" ] || touch "${shell-rc}"
    # shellcheck disable=SC2016
    if ! grep -Fq '${sourceCommand}' "${shell-rc}"; then
      # shellcheck disable=SC2016
      echo '${sourceCommand}' >> "${shell-rc}"
    fi

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

    ${afterActivationCommands}
  '';
}
