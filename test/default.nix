{
  pkgs,
  lib,
  ...
}:
{
  away = {
    username = "bobymoby";
    file = {
      ".file" = {
        source = ./file;
      };
      ".config/folder3" = {
        source = ./folder;
        recursive = true;
      };
      ".my-symlink".source = lib.am.mkOutOfStoreSymlink "/home/bobymoby/some/target";
    };

    packages = with pkgs; [
      gcc
    ];
  };
}
