{ pkgs, ... }:
eval:
pkgs.nixosOptionsDoc {
  options = removeAttrs eval.options [ "_module" ];
  warningsAreErrors = false;
  documentType = "none";
}
