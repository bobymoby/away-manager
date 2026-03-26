{
  self,
  pkgs,
  lib,
  ...
}@inputs:
file:
lib.evalModules {
  modules = [
    file
    "${self}/modules"
  ];

  specialArgs = {
    inherit pkgs lib inputs;
  };

  # check = false;
}
