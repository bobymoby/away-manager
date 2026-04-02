{ pkgs }:
pkgs.writeShellApplication {
  name = "away-manager";
  runtimeInputs = with pkgs; [
    jq
  ];
  text = builtins.readFile ./away-manager.sh;
}
