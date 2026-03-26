{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
  };

  outputs =
    inputs@{ self, nixpkgs, ... }:
    let
      system = "x86_64-linux";
      pkgs = nixpkgs.legacyPackages.${system};
      customLib = import ./lib {
        inherit pkgs;
        lib = pkgs.lib;
      };
      lib = pkgs.lib // customLib;
    in
    {
      packages.${system}.default = import ./runner/runner.nix {
        inherit pkgs lib self;
      } ./test/default.nix;

      test = (import ./runner/runner.nix { inherit pkgs lib; }) ./test/default.nix;
    };
}
