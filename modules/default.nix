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
    # home = lib.mkOption {
    #   type = lib.types.str;
    #   default = "/home/${config.username}";
    # };
    add-gc-root = lib.mkOption {
      type = lib.types.bool;
      default = true;
    };
  };
}
