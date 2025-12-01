{ inputs, ... }:
let
  overlay = final: prev: {
    local = inputs.self.packages.${prev.stdenv.hostPlatform.system};
    inherit (prev.lixPackageSets.latest)
      nixpkgs-review
      nix-eval-jobs
      nix-fast-build
      colmena
      ;
  };
in
{
  config = {

    flake.modules.nixos.nixos =
      { pkgs, ... }:
      {

        # imports = [
        #   inputs.lix-module.nixosModules.default
        # ];

        config = {
          nixpkgs.overlays = [
            overlay
          ];
          nix.package = pkgs.lixPackageSets.latest.lix;
        };

      };

  };
}
