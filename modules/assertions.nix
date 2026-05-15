{
  lib,
  config,
  pkgs,
  ...
}:
let
  assertionType = lib.types.submodule {
    options = {
      assertion = lib.mkOption {
        type = lib.types.bool;
      };
      message = lib.mkOption {
        type = lib.types.str;
      };
    };
  };
in
{
  options.away.assertions = lib.mkOption {
    type = lib.types.listOf assertionType;
    default = [ ];
  };
}
