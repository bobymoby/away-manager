{
  lib,
  ...
}:

{
  imports = [
    ./file.nix
    ./packages.nix
    ./away-manager-cli.nix
  ];

  options.away = {
    username = lib.mkOption {
      type = lib.types.str;
    };
    add-gc-root = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };
  };
}
