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
          ];
        };
      };

    flake.modules.nixos.nixos = {
      nixpkgs.overlays = [
        overlay
      ];
    };

    flake-file.inputs = {
      nixpkgs.url = "github:nixos/nixpkgs/nixos-25.11";
      nixpkgs-darwin.url = "github:nixos/nixpkgs/nixpkgs-25.11-darwin";
      nixpkgs-lib.url = "github:nix-community/nixpkgs.lib";
    };

  };
}
