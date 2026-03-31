{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs =
    {
      self,
      flake-utils,
      nixpkgs,
      ...
    }:
    (flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = import nixpkgs { inherit system; };
      in
      {
        packages.default = import ./cli { inherit pkgs; };
        packages.test1 =
          import ./parser/files-package.nix
            {
              inherit self pkgs;
              lib = (import ./lib/flake-lib.nix { inherit self; }).mkLib pkgs;
            }
            (import ./parser/loader.nix {
              inherit self pkgs;
              lib = (import ./lib/flake-lib.nix { inherit self; }).mkLib pkgs;
            } ./test/test.nix).config.away;
        packages.test2 = self.lib.mkAwayConfiguration {
          inherit pkgs;
          modules = [ ./test/test.nix ];
        };
      }
    ))
    // {
      lib = import ./lib/flake-lib.nix { inherit self; };
    };
}
