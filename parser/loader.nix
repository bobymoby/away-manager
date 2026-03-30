{
  self,
  pkgs,
  lib,
  ...
}@inputs:
modules:
let
  modulesList = if builtins.isList modules then modules else [ modules ];
in
lib.evalModules {
  modules = modulesList ++ [ "${self}/modules" ];

  specialArgs = {
    inherit pkgs lib inputs;
  };

  # check = false;
}
