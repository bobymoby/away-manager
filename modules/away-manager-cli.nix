{
  lib,
  config,
  pkgs,
  ...
}:
let
  away-manager-cli = import ../cli { inherit pkgs; };
in
{
  options.away.away-manager-cli = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };
    package = lib.mkOption {
      type = lib.types.package;
      default = away-manager-cli;
    };
  };

  config.away.packages = lib.mkIf config.away.away-manager-cli.enable [
    config.away.away-manager-cli.package
  ];
}
