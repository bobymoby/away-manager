{
  lib,
  config,
  ...
}:

{
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
  };
}
