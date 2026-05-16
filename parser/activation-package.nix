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
    text = lib.am.concatStringsNewLine (
      map (relPath: "${cfg.home}/${relPath}") (builtins.attrNames cfg.file)
    );
  };

  envScript = pkgs.writeTextFile {
    name = "away-manager-source-rc.sh";
    text = lib.am.concatStringsNewLine (
      [
        cfg.shell-rc-path-command
        "\n"
      ]
      ++ lib.mapAttrsToList (
        k: v: "export ${k}=\"${lib.replaceStrings [ "\\" "\"" ] [ "\\\\" "\\\"" ] v}\""
      ) cfg.env-variables
    );
  };

  activateScript = mkActivateScript {
    inherit managedPathsFile;
    inherit (cfg)
      username
      shell-rc
      home
      gen-dir
      profile-dir
      script-extensions
      ;

    fileCommands =
      let
        fileMapper =
          relPath:
          let
            targetExpr = "${cfg.home}/${relPath}";
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
    inherit (cfg)
      username
      gen-dir
      profile-dir
      script-extensions
      ;
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
    ln -s "${envScript}" "$out/away-manager-source-rc.sh"
  ''
  + lib.optionalString cfg.docs.enable ''ln -s "${docsDerivation}" "$out/docs.md"'';
}
