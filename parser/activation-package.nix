{
  pkgs,
  lib,
  self,
  ...
}@inputs:
let
  mkFilesPackage = import ./files-package.nix inputs;
  mkActivateScript = import ./activate-script.nix inputs;
  mkUninstallScript = import ./uninstall-script.nix inputs;
  mkDocs = import ./docs.nix inputs;
in

eval:
let
  cfg = eval.config.away;
  packageEnv = pkgs.buildEnv {
    name = "away-manager-packages";
    paths = cfg.packages;
  };

  files-package = mkFilesPackage cfg;

  managedPathsFile = pkgs.writeTextFile {
    name = "managed-paths";
    text = builtins.concatStringsSep "\n" (
      lib.mapAttrsToList (relPath: _: "/home/${cfg.username}/${relPath}") cfg.file
    );
  };

  activateScript = mkActivateScript {
    inherit managedPathsFile;
    inherit (cfg) username;

    fileCommands =
      let
        fileMapper =
          relPath:
          let
            targetExpr = "$HOME_DIR/${relPath}";
          in
          ''
            mkdir -p "$(dirname "${targetExpr}")"
            rm -rf "${targetExpr}"
            ln -s "${files-package}/${relPath}" "${targetExpr}"
          '';
      in
      map fileMapper (builtins.attrNames cfg.file);
  };
  uninstallScript = mkUninstallScript {
    inherit (cfg) username;
  };

  docsDerivation = (mkDocs eval).optionsCommonMark;
in
pkgs.stdenv.mkDerivation {
  name = "away-manager-activate-${cfg.username}";

  dontUnpack = true;
  dontBuild = true;

  installPhase = ''
    mkdir -p "$out/bin"

    ln -s "${lib.getExe activateScript}" "$out/bin/away-manager-activate"
    ln -s "${lib.getExe uninstallScript}" "$out/bin/away-manager-uninstall"

    ln -s "${managedPathsFile}" "$out/managed-paths"
    ln -s "${packageEnv}" "$out/packages"
    ln -s "${files-package}" "$out/files"
  ''
  + lib.optionalString cfg.docs.enable ''ln -s "${docsDerivation}" "$out/docs.md"'';
}
