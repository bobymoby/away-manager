{
  pkgs,
  lib,
  self,
  ...
}@inputs:
let
  loadConfig = import "${self}/loader/loader.nix" inputs;
in

file:
let
  eval = loadConfig file;
  cfg = eval.config.away;

  packageEnv = pkgs.buildEnv {
    name = "away-manager-packages";
    paths = cfg.packages;
  };

  fileCommands =
    let
      inherit (builtins)
        isPath
        isString
        isAttrs
        hasAttr
        ;

      fileMapper =
        relPath: value:
        assert (isAttrs value && hasAttr "source" value) || throw "Invalid file entry for ${relPath}";

        let
          targetExpr = "$HOME_DIR/${relPath}";

          linkCmd =
            if isPath value.source || isString value.source then
              ''ln -s "${value.source}" "${targetExpr}"''
            else if lib.am.types.isOutOfStoreSymlink value.source then
              ''ln -s "${value.source.args.path}" "${targetExpr}"''
            else
              throw "Invalid file entry for ${relPath}";
        in
        ''
          mkdir -p "$(dirname "${targetExpr}")"
          rm -rf "${targetExpr}"
          ${linkCmd}
        '';
    in
    lib.mapAttrsToList fileMapper (cfg.file);

  activationPackage = pkgs.stdenv.mkDerivation {
    pname = "away-manager-activate";
    version = "0.1.0";

    dontUnpack = true;
    dontBuild = true;

    installPhase = ''
      mkdir -p "$out/bin"

      cat > "$out/bin/away-manager-activate" <<'EOF'
      #!${pkgs.bash}/bin/bash
      set -euo pipefail
      PATH='${
        lib.makeBinPath (
          with pkgs;
          [
            coreutils
            findutils
            gnugrep
          ]
        )
      }':"$PATH"

      HOME_DIR="''\${AWAY_HOME:-''\${HOME:-/home/${cfg.username}}}"
      GEN_DIR="''\${AWAY_GEN_DIR:-$HOME_DIR/.away-manager}"

      mkdir -p "$HOME_DIR" "$GEN_DIR"

      PREV_GEN_PATH=""
      if [ -L "$GEN_DIR/current" ]; then
        PREV_GEN_PATH="$(readlink -f "$GEN_DIR/current")"
      fi

      GEN_PATH="$GEN_DIR/gen-$(date +%s)"
      mkdir -p "$GEN_PATH"
      MANAGED_PATHS_FILE="$GEN_PATH/managed-paths"

      ln -sfn "${packageEnv}" "$GEN_PATH/packages"

      cat > "$MANAGED_PATHS_FILE" <<EOF2
      ${builtins.concatStringsSep "\n" (lib.mapAttrsToList (relPath: _: "$HOME_DIR/${relPath}") cfg.file)}
      EOF2

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
      # ensure_path_in_shell_rc "$HOME_DIR/.zshrc"

      if [ -n "$PREV_GEN_PATH" ] && [ -f "$PREV_GEN_PATH/managed-paths" ]; then
        while IFS= read -r relPath; do
          [ -n "$relPath" ] || continue
          if ! grep -Fxq "$relPath" "$MANAGED_PATHS_FILE"; then
            rm -rf "$relPath"
          fi
        done < "$PREV_GEN_PATH/managed-paths"
      fi

      ${builtins.concatStringsSep "\n\n" fileCommands}

      ln -sfn "$GEN_PATH" "$GEN_DIR/current"
      ln -sfn "$GEN_DIR/current/packages" "$HOME_DIR/.away-manager-profile"
      EOF

      cat > "$out/bin/away-manager-uninstall" <<'EOF'
      #!${pkgs.bash}/bin/bash
      set -euo pipefail
      PATH='${
        lib.makeBinPath (
          with pkgs;
          [
            coreutils
            findutils
            gnugrep
          ]
        )
      }':"$PATH"

      HOME_DIR="''\${AWAY_HOME:-''\${HOME:-/home/${cfg.username}}}"
      GEN_DIR="''\${AWAY_GEN_DIR:-$HOME_DIR/.away-manager}"
      CURRENT_GEN_PATH=""

      if [ -L "$GEN_DIR/current" ]; then
        CURRENT_GEN_PATH="$(readlink -f "$GEN_DIR/current")"
      fi

      if [ -n "$CURRENT_GEN_PATH" ] && [ -f "$CURRENT_GEN_PATH/managed-paths" ]; then
        while IFS= read -r relPath; do
          [ -n "$relPath" ] || continue
          rm -rf "$relPath"
        done < "$CURRENT_GEN_PATH/managed-paths"
      fi

      rm -f "$HOME_DIR/.away-manager-profile"
      rm -f "$GEN_DIR/current"
      rm -rf "$GEN_DIR"
      EOF

      chmod +x "$out/bin/away-manager-activate"
      chmod +x "$out/bin/away-manager-uninstall"
    '';
  };
in
pkgs.stdenv.mkDerivation {
  pname = "away-manager";
  version = "0.1.0";

  dontUnpack = true;
  dontBuild = true;

  installPhase = ''
    mkdir -p "$out/bin"
    ln -s "${activationPackage}/bin/away-manager-activate" "$out/bin/away-manager-activate"
    ln -s "${activationPackage}/bin/away-manager-uninstall" "$out/bin/away-manager-uninstall"
  '';
}
