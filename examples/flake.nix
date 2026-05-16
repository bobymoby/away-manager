{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
    away-manager = {
      # url = "github:bobymoby/away-manager";
      url = "path:/home/bobymoby/Projects/away-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      away-manager,
    }:
    let
      pkgs = import nixpkgs {
        system = "x86_64-linux";
      };
    in
    {
      awayConfigurations.test = away-manager.lib.mkAwayConfiguration {
        inherit pkgs;
        modules = [ ./away.nix ];
      };
    };
}
