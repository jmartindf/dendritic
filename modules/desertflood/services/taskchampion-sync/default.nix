# SPDX-FileCopyrightText: 2025 Joe Martin <joe@desertflood.com>
# SPDX-License-Identifier: BlueOak-1.0.0
_: {
  df.services.taskchampion-sync = {

    traefik-apps =
      { config, ... }:
      let
        inherit (config.services.taskchampion-sync-server) host port;
      in
      {
        taskchamp = {
          rule = "Host(`taskchamp.desertflood.com`)";
          url = "http://${toString host}:${toString port}";
          middlewares = "chain-no-auth@file";
        };
      };

    nixos =
      { pkgs, ... }:
      {
        services.taskchampion-sync-server = {
          enable = true;
          package = pkgs.taskchampion-sync-server;
          allowClientIds = [ "5D51EACB-0887-4258-8D84-12B0239E280C" ];
        };

        # systemd.services.taskchampion-sync-server.environment = {
        #   RUST_LOG = "debug";
        # };

      };
  };
}
