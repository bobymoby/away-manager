{
  self,
  pkgs,
  lib,
  ...
}@inputs:
modules:
let
  modulesList = if builtins.isList modules then modules else [ modules ];
  loadedModules = lib.evalModules {
    modules = modulesList ++ [ "${self}/modules" ];

    specialArgs = {
      inherit pkgs lib inputs;
    };

    # check = false;
  };
  assertions = loadedModules.config.away.assertions;
  falseAssertions = builtins.filter (assertion: !assertion.assertion) assertions;
  falseAssertionsMessages = builtins.concatStringsSep "\n" (
    map (assertion: assertion.message) falseAssertions
  );
in
if falseAssertions != [ ] then throw "\n${falseAssertionsMessages}" else loadedModules
