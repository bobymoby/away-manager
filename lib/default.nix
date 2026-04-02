{ lib, ... }:

let
  inherit (lib) foldr recursiveUpdate;
in
{
  am = rec {
    debug = {
      print = value: builtins.trace (toString value) value;
    };

    types = rec {
      outOfStoreSymlink = lib.types.mkOptionType {
        name = "out-of-store-symlink";
        check = isOutOfStoreSymlink;
      };

      isOutOfStoreSymlink =
        value:
        builtins.isAttrs value
        && builtins.hasAttr "type" value
        # && value.type == types.outOfStoreSymlink
        && builtins.hasAttr "args" value
        && builtins.isAttrs value.args
        && builtins.hasAttr "path" value.args
        && (builtins.isPath value.args.path || builtins.isString value.args.path);
    };

    mkType =
      { type, args }:
      {
        inherit type args;
      };

    mkOutOfStoreSymlink =
      path:
      mkType {
        type = types.outOfStoreSymlink;
        args = { inherit path; };
      };

    mergeAttrSets = listArrtSets: foldr recursiveUpdate { } listArrtSets;

    importNixFilesRecursive =
      dir:
      let
        inherit (builtins)
          readDir
          concatLists
          attrNames
          match
          ;
        entries = readDir dir;
        fileMapper =
          name:
          let
            fileType = entries.${name};
            path = dir + "/${name}";
          in
          if fileType == "directory" then
            importNixFilesRecursive path
          else if fileType == "regular" && match ".*\\.nix" name != null then
            [ path ]
          else
            [ ];
      in
      concatLists (map fileMapper (attrNames entries));
  };
}
