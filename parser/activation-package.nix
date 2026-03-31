{
  pkgs,
  lib,
  self,
  ...
}@inputs:
let
  loadConfig = import ./loader.nix inputs;
  mkFilesPackage = import ./files-package.nix inputs;
in

modules:
let
  eval = loadConfig modules;
  cfg = eval.config.away;

  packageEnv = pkgs.buildEnv {
    name = "away-manager-packages";
    paths = cfg.packages;
  };

  files-package = mkFilesPackage cfg;

  fileCommands =
    let
      inherit (builtins)
        isPath
        pathExists
        readDir

        isString
        stringLength
        substring

        isAttrs
        hasAttr
        ;

      # dirReader =
      #   let
      #     dirMapper =
      #       rootDir: currDir: relPath: type:
      #       let
      #         path = currDir + "/${relPath}";
      #       in
      #       if type == "regular" then
      #         substring (stringLength (toString rootDir) + 1) (-1) (toString path)
      #       else if type == "directory" then
      #         dirReader' rootDir path
      #       else
      #         throw "Invalid file entry for ${relPath}";

      #     dirReader' = rootDir: dir: lib.flatten (lib.mapAttrsToList (dirMapper rootDir dir) (readDir dir));
      #   in
      #   startDir: dirReader' startDir startDir;

      fileMapper =
        relPath: value:
        # assert
        #   (isAttrs value) && (lib.xor (hasAttr "source" value) (hasAttr "text" value))
        #   || throw "Invalid file entry for ${relPath}";

        let
          targetExpr = "$HOME_DIR/${relPath}";
          textFileLocation = pkgs.writeTextFile {
            name = relPath;
            inherit (value) text executable;
          };
          mkFilesPackagePath =
            source:
            # ''$(readlink -e "${files-package}/${source}")'';
            "${files-package}/${source}";
          mkLn = source: ''ln -s "${source}" "${targetExpr}"'';

          # linkCmd = mkLn (
          #   if hasAttr "text" value && !(isNull value.text) then
          #     throw "Not yet implemented"
          #   else if
          #     (hasAttr "source" value && isPath value.source && pathExists value.source) || isString value.source
          #   then
          #     mkFilesPackagePath value.source
          #   else if lib.am.types.isOutOfStoreSymlink value.source then
          #     value.source.args.path
          #   else
          #     throw "Invalid file entry for ${relPath}: ${toString value.source}"
          # );
        in
        ''
          mkdir -p "$(dirname "${targetExpr}")"
          rm -rf "${targetExpr}"
          ${mkLn (mkFilesPackagePath relPath)}
        '';
    in
    lib.mapAttrsToList fileMapper cfg.file;
in
pkgs.stdenv.mkDerivation {
  name = "away-manager-activate-${cfg.username}";

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

    mkdir -p "$out/packages"
    ln -sfn "${packageEnv}" "$out/packages"
  '';
}
