{ lib, ... }:
{
  options.away.script-extensions = {
    beforeActivation = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
    };
    afterActivation = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
    };
    beforeUninstall = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
    };
    afterUninstall = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
    };
  };
}
