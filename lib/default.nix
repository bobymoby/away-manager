{ lib, ... }:

let
  inherit (lib) foldr recursiveUpdate;
in
{
  am = rec {
    debug = {
      print = value: builtins.trace (toString value) value;
    };

    types = {
      outOfStoreSymlink = "out-of-store-symlink";

      isOutOfStoreSymlink =
        value:
        builtins.isAttrs value
        && builtins.hasAttr "type" value
        && value.type == types.outOfStoreSymlink
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
  };
}
