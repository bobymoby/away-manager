{
  pkgs,
  lib,
  self,
  ...
}@inputs:
file:
let
  loadedConfig = ((import "${self}/loader/loader.nix" inputs) file).config.away;
  fileCommands =
    let
      fileMapper =
        name: value:
        assert
          (builtins.isAttrs value && builtins.hasAttr "source" value)
          || throw "Invalid file entry for ${name}";
        if builtins.isPath value.source || builtins.isString value.source then
          "ln -s ${value.source} /home/${loadedConfig.username}/${name}"
        else if lib.am.types.isOutOfStoreSymlink value.source then
          "ln -s ${value.source.args.path} $out"
        else
          value.source.type;
    in
    lib.mapAttrsToList fileMapper loadedConfig.file;
  packageEnv = pkgs.buildEnv {
    name = "away-manager-packages";
    paths = loadedConfig.packages;
  };
in
pkgs.stdenv.mkDerivation rec {
  name = "away-manager-generation";
  src = "${self}";

  GEN_DIR = "/home/${loadedConfig.username}/.away-manager";

  buildPhase = ''
    cat <<EOF > ./myScript
    #!/usr/bin/env bash
    ${builtins.concatStringsSep "\n" fileCommands}
    EOF

    cat <<EOF > ./envScript
    #!/usr/bin/env bash
    set -euo pipefail

    mkdir -p "$GEN_DIR"

    GEN_PATH="${GEN_DIR}/gen-$(date +%s)"

    ln -s ${packageEnv} "\$GEN_PATH"
    ln -sfn "\$GEN_PATH" "$GEN_DIR/current"
    EOF

    chmod +x ./myScript
    chmod +x ./envScript
  '';

  installPhase = ''
    mkdir -p $out
    mv ./myScript $out/
    mv ./envScript $out/
  '';
}
