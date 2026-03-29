# Away Manager

Home manager but away

```nix
{
  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";

    away-manager = {
      url = "github:bobymoby/away-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      nixpkgs,
      away-manager,
      ...
    }:
    let
      pkgs = import nixpkgs { system = "x86_64-linux"; };
    in
    {
      awayConfigurations.<config-name> = away-manager.lib.mkAwayConfiguration {
        inherit pkgs;
        modules = [ ./default.nix ];
      };
    };
}
```

```bash
nix run github:bobymoby/away-manager -- switch --flake <flake-ref>#awayConfigurations.<config-name>
```