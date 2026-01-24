{
  inputs,
  ...
}:
{
  # SPDX-FileCopyrightText: 2025 Joe Martin <joe@desertflood.com>
  # SPDX-License-Identifier: BlueOak-1.0.0

  imports = [ inputs.home-manager.flakeModules.home-manager ];

  options = { };

  config = {

    flake.modules = {

      nixos.nixos =
        { ... }:
        {

          imports = [ inputs.home-manager.nixosModules.home-manager ];

          config = {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
          };

        };

      darwin.darwin =
        { ... }:
        {

          imports = [ inputs.home-manager.darwinModules.home-manager ];

          config = {
            home-manager.useGlobalPkgs = true;
            home-manager.useUserPackages = true;
          };

        };

      homeManager.core =
        {
          lib,
          pkgs,
          config,
          ...
        }:
        {
          home = {
            username = lib.mkDefault "jmartin";
            homeDirectory = "/${if pkgs.stdenv.isLinux then "home" else "Users"}/${config.home.username}";
            stateVersion = "24.11";
          };

          # Let Home Manager install and manage itself.
          programs.home-manager.enable = true;
        };

    };

    flake-file.inputs.home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

  };

}
