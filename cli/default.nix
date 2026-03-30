{ pkgs }:
pkgs.writeShellApplication {
  name = "away-manager";
  text = ./away-manager.sh;
}
