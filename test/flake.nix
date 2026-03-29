{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    away-manager = {
      url = "path:/home/bobymoby/Projects/away-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      away-manager,
      ...
    }:
    let
      pkgs = import nixpkgs { system = "x86_64-linux"; };
    in
    {
      awayConfigurations.bobymoby = away-manager.lib.mkAwayConfiguration {
        inherit pkgs;
        modules = [ ./default.nix ];
      };
    };
}
