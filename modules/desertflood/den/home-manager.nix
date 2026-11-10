# SPDX-FileCopyrightText: 2025 Joe Martin <joe@desertflood.com>
# SPDX-License-Identifier: BlueOak-1.0.0
{
  den,
  inputs,
  ...
}:
let
  osContext =
    { host }:
    {
      ${host.class} = {
        config = {
          home-manager = {
            useGlobalPkgs = true;
            useUserPackages = true;
            backupFileExtension = "backup";
            overwriteBackup = true;
          };
        };
      };
    };

  homeContext =
    {
      host,
      user,
    }:
    {
      homeManager = builtins.traceVerbose "enable home-manager for ${user.userName}@${host.name}" {
        # Let Home Manager install and manage itself.
        programs.home-manager.enable = true;
      };
    };
in
{

  imports = [ inputs.home-manager.flakeModules.home-manager ];

  config = {

    den.schema.host.includes = [ osContext ];
    df.base.includes = [ homeContext ];

    flake-file.inputs.home-manager = {
      url = "github:nix-community/home-manager/release-26.05";
      inputs.nixpkgs.follows = "nixpkgs";
    };

  };
}
