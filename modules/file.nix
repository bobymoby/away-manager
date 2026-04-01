{ lib, ... }:

let
  fileSourceType = lib.types.oneOf [
    lib.types.path
    lib.types.str
    lib.am.types.outOfStoreSymlink
  ];

  fileType = lib.types.submodule {
    options = {
      source = lib.mkOption {
        type = lib.types.nullOr fileSourceType;
        default = null;
      };
      recursive = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };
      text = lib.mkOption {
        type = lib.types.nullOr lib.types.str;
        default = null;
      };
      executable = lib.mkOption {
        type = lib.types.bool;
        default = false;
      };
    };
  };
in
{
  options.away.file = lib.mkOption {
    type = lib.types.attrsOf fileType;
    default = { };
  };
}
