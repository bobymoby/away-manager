{
  lib,
  ...
}@inputs:

{
  options.away = lib.am.mergeAttrSets [
    (import ./file.nix inputs)
    (import ./packages.nix inputs)
    {
      username = lib.mkOption {
        type = lib.types.str;
      };
    }
  ];
}
