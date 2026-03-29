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

  options.away.username = lib.mkOption {
    type = lib.types.str;
  };
}
