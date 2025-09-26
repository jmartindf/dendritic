_: {
  # SPDX-FileCopyrightText: 2025 Joe Martin <joe@desertflood.com>
  # SPDX-License-Identifier: BlueOak-1.0.0

  flake.modules.nixos.nixos =
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

      options = {

        desertflood.shared-secrets = {

          smtp = {
            enable = lib.mkEnableOption {
              description = "Make SMTP login info available for this host";
              default = false;
            };
          };

        };

      };

      config = {

        desertflood.shared-secrets = { };

        age.secrets = lib.mkMerge [
          (lib.mkIf nixOScfg.desertflood.shared-secrets.smtp.enable {
            smtp-user.rekeyFile = ./smtp-user.age;
            smtp-password.rekeyFile = ./smtp-password.age;
            smtp-server.rekeyFile = ./smtp-server.age;
          })
        ];

      };
    };
}
