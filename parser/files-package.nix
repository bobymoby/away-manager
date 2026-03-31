{
  pkgs,
  lib,
  self,
  ...
}:
cfg:
let
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
          targetExpr = "$out/${relPath}";
          textFileLocation = pkgs.writeTextFile {
            name = relPath;
            inherit (value) text executable;
          };
          mkLn = source: ''ln -s "${source}" "${targetExpr}"'';

          linkCmd = mkLn (
            if hasAttr "text" value && !(isNull value.text) then
              textFileLocation
            else if
              (hasAttr "source" value && isPath value.source && pathExists value.source) || isString value.source
            then
              value.source
            else if lib.am.types.isOutOfStoreSymlink value.source then
              # value.source.args.path
              value.source.args.path
            else
              throw "Invalid file entry for ${relPath}."
          );
        in
        ''
          mkdir -p "$(dirname "${targetExpr}")"
          rm -rf "${targetExpr}"
          ${linkCmd}
        '';
    in
    lib.mapAttrsToList fileMapper cfg.file;
in

pkgs.stdenv.mkDerivation {
  name = "away-manager-files";
  dontUnpack = true;
  dontBuild = true;
  installPhase = ''
    ${builtins.concatStringsSep "\n\n" fileCommands}
  '';
}
