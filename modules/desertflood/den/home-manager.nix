# SPDX-FileCopyrightText: 2025 Joe Martin <joe@desertflood.com>
# SPDX-License-Identifier: BlueOak-1.0.0
{
  den,
  inputs,
  ...
}:
let
  osContext = den.lib.take.exactly (
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
    }
  );

  homeContext = den.lib.take.exactly (
    {
      host,
      user,
    }:
    {
      homeManager = builtins.traceVerbose "enable home-manager for ${user.userName}@${host.name}" {
        # Let Home Manager install and manage itself.
        programs.home-manager.enable = true;
      };
    }
  );
in
{

  imports = [ inputs.home-manager.flakeModules.home-manager ];

  config = {

    df.base.includes = [
      osContext
      homeContext
    ];

    flake-file.inputs.home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };

  };
}
