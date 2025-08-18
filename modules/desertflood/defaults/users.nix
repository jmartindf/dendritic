# SPDX-FileCopyrightText: 2025 Joe Martin <joe@desertflood.com>
# SPDX-License-Identifier: BlueOak-1.0.0
#
{
  # Pre-configured user details
  config,
  lib,
  ...
}:
let
  inherit (lib) mkDefault;
  flakeCfg = config;
in
{
  config.desertflood = {

    defaultUser = lib.mkDefault flakeCfg.desertflood.users.users.joe;

    users.users = {

      joe = {
        fullName = mkDefault "Joe Martin";

        emails = mkDefault {
          family.email = "joe@thosemartins.family";
          thosemartins.email = "joe@thosemartins.net";
          desertflood.email = "joe@desertflood.com";
        };

        authorizedKeys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILmB+dj98dHaQuaK0qcxTVpJxVAongswoUSZFOPrM4UW"
        ];
      };

    };
  };
}
