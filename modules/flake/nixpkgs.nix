{ inputs, ... }:
let
  overlay = final: prev: {
    local = inputs.self.packages.${prev.system};
  };
in
{
  config = {
    flake.modules.nixos.nixos = {
      nixpkgs.overlays = [
        overlay
      ];
    };
  };
}
