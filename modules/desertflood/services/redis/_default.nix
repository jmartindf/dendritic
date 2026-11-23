_: {
  # SPDX-FileCopyrightText: 2025 Joe Martin <joe@desertflood.com>
  # SPDX-License-Identifier: BlueOak-1.0.0

  config = {

    flake.modules.nixos.services =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      let
        nixOScfg = config;
      in
      {
        imports = [ ];

        options = {

          desertflood.services.redis = {
            enable = lib.mkEnableOption {
              default = false;
              description = "Redis caching server";
            };
          };

        };

        config = lib.mkIf nixOScfg.desertflood.services.redis.enable {

          age.secrets.redis-password.rekeyFile = ./redis-password.age;

          services.redis.servers."" = {
            enable = true;
            bind = "127.0.0.1";
            requirePassFile = nixOScfg.age.secrets.redis-password.path;
          };

        };
      };

  };
}
