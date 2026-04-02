{
  lib,
  config,
  ...
}:

{
  imports = builtins.filter (file: file != ./default.nix) (lib.am.importNixFilesRecursive ./.);

  options.away = {
    username = lib.mkOption {
      type = lib.types.str;
      description = "The username of the user to manage";
    };
    home = lib.mkOption {
      type = lib.types.str;
      default = "/home/${config.away.username}";
      description = "The home directory of the user to manage";
    };
    gen-dir = lib.mkOption {
      type = lib.types.str;
      default = "${config.away.home}/.away-manager";
      description = "The directory where the away-manager files are stored";
    };
    docs.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to generate documentation for the away-manager configuration";
    };
    # add-gc-root = lib.mkOption {
    #   type = lib.types.bool;
    #   default = true;
    # };
  };
}
