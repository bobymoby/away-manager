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
          mkFilesPackagePath = path: "${files-package}/${path}";
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

  managedPathsFile = pkgs.writeTextFile {
    name = "managed-paths";
    text = builtins.concatStringsSep "\n" (
      lib.mapAttrsToList (relPath: _: "/home/${cfg.username}/${relPath}") cfg.file
    );
  };
  activateScript = import ./activate-script.nix inputs {
    inherit managedPathsFile fileCommands;
    inherit (cfg) username;
  };
  uninstallScript = import ./uninstall-script.nix inputs {
    inherit (cfg) username;
  };
in
pkgs.stdenv.mkDerivation {
  name = "away-manager-activate-${cfg.username}";

  dontUnpack = true;
  dontBuild = true;

  installPhase = ''
    mkdir -p "$out/bin"

    ln -s "${managedPathsFile}" "$out/managed-paths"
    ln -s "${lib.getExe activateScript}" "$out/bin/away-manager-activate"
    ln -s "${lib.getExe uninstallScript}" "$out/bin/away-manager-uninstall"

    ln -s "${packageEnv}" "$out/packages"
    ln -s "${files-package}" "$out/files"
  '';
}
