{ pkgs }:
pkgs.writeShellApplication {
  name = "away-manager";
  text = builtins.readFile ./away-manager.sh;
}
