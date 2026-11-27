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
  df.lix.nixos =
    { pkgs, ... }:
    {
      nixpkgs.overlays = [
        overlay
      ];
      nix.package = pkgs.lixPackageSets.latest.lix;
    };
}
