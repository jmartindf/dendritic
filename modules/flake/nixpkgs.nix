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
      {
        _module.args.pkgs = import inputs.nixpkgs {
          inherit system;
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
