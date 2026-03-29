{
  lib,
  ...
}:

{
  options.away.packages = lib.mkOption {
    default = [ ];
  };
}
