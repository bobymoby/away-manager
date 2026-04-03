{
  lib,
  config,
  ...
}:

{
  imports = builtins.filter (file: file != ./default.nix) (
    lib.am.importNixFilesRecursive ./.
  );

  options.away = {
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
