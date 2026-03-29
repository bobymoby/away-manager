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
    import "${self}/runner/runner.nix" {
      inherit pkgs self;
      lib = mkLib pkgs;
    };
in
{
  mkAwayConfiguration = { pkgs, modules }: mkAwayPackage pkgs modules;
}
