{
  lib,
  ...
}:

{
  options.away.packages = lib.mkOption {
    type = lib.types.listOf lib.types.package;
    default = [ ];
  };
}
