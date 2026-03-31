{ self }:
let
  mkLib =
    pkgs:
    pkgs.lib
    // (import ./. {
      inherit pkgs;
      lib = pkgs.lib;
    });

  mkAwayPackage =
    pkgs:
    import "${self}/parser/activation-package.nix" {
      inherit pkgs self;
      lib = mkLib pkgs;
    };
in
{
  inherit mkLib;
  mkAwayConfiguration = { pkgs, modules }: mkAwayPackage pkgs modules;
}
