{
  pkgs,
  lib,
  self,
  ...
}:
{
  file,
  username,
  ...
}:
let
  fileCommands =
    let
      inherit (builtins)
        isPath
        pathExists

        isString

        hasAttr
        ;

      fileMapper =
        relPath: value:
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
              (hasAttr "source" value && isPath value.source && pathExists value.source)
              || isString value.source
            then
              value.source
            else if lib.am.types.isOutOfStoreSymlink value.source then
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
    lib.mapAttrsToList fileMapper file;
in
pkgs.runCommand "away-manager-files" { } ''
  mkdir -p $out

  ${builtins.concatStringsSep "\n" fileCommands}
''
