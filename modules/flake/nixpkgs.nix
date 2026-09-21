{ inputs, ... }:
let
  overlay = final: prev: {
    local = inputs.self.packages.${prev.stdenv.hostPlatform.system};
  };
in
{
  config = {

    perSystem =
      { system, config, ... }:
      let
        whichpkgs = if system == "aarch64-darwin" then "nixpkgs-darwin" else "nixpkgs";
      in
      {
        _module.args.pkgs = import inputs.${whichpkgs} {
          inherit system;
          config.allowUnfree = true; # Allow devshells, etc to use unfree packages
          overlays = [
            (final: prev: {
              local = config.packages;
            })
            inputs.bun2nix.overlays.default
          ];
        };
      };

    flake.modules.nixos.nixos = {
      nixpkgs.overlays = [
        overlay
        inputs.bun2nix.overlays.default
      ];
    };

    flake-file.inputs = {
      nixpkgs.url = "https://channels.nixos.org/nixos-26.05/nixexprs.tar.zst";
      nixpkgs-darwin.url = "https://channels.nixos.org/nixpkgs-26.05-darwin/nixexprs.tar.zst";
      nixpkgs-unstable.url = "https://channels.nixos.org/nixpkgs-unstable/nixexprs.tar.zst";
      nixpkgs-lib.url = "github:nix-community/nixpkgs.lib";
    };

  };
}
