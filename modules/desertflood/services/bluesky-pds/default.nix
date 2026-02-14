_: {
  # SPDX-FileCopyrightText: 2025 Joe Martin <joe@desertflood.com>
  # SPDX-License-Identifier: BlueOak-1.0.0

  imports = [ ];

  options = { };

  config = {

    flake.modules.nixos.services =
      {
        lib,
        pkgs,
        config,
        ...
      }:
      let
        nixOScfg = config;
        dfCfg = nixOScfg.desertflood;
        svcsConfig = dfCfg.services;
      in
      {

        imports = [ ];

        options = {

          desertflood.services.bluesky-pds = {
            enable = lib.mkEnableOption "Bluesky PDS (Personal Data Server)";

            port = lib.mkOption {
              type = lib.types.port;
              default = dfCfg.globals.ports.bluesky-pds;
              description = "The local port for the PDS to listen on";
            };
          };
        };

        config = lib.mkIf svcsConfig.bluesky-pds.enable {

          desertflood.networking.services.bluesky-pds = { };

          age.secrets.bluesky-env = {
            rekeyFile = ./bluesky.env.age;
            name = "bluesky.env";
            mode = "0600";
            generator.script =
              let
                envTemplate = ./bluesky.env;
              in
              { lib, ... }: # bash
              ''
                cat ${lib.escapeShellArg envTemplate} | op inject
              '';
          };

          services.bluesky-pds = {

            enable = true;

            package = pkgs.bluesky-pds;

            environmentFiles = [ nixOScfg.age.secrets.bluesky-env.path ];

            settings = {
              PDS_HOSTNAME = "${dfCfg.networking.services.bluesky-pds.fqdn}";
              PDS_PORT = svcsConfig.bluesky-pds.port;
              PDS_INVITE_REQUIRED = "true";
              PDS_EMAIL_FROM_ADDRESS = "admin@desertflood.com";
              PDS_BLOBSTORE_DISK_LOCATION = null; # Storing on Backblaze B2
              PDS_BLOBSTORE_S3_BUCKET = "df-bsky-pds";
              PDS_BLOBSTORE_S3_REGION = "us-west-001";
              PDS_BLOBSTORE_S3_ENDPOINT = "https://s3.us-west-001.backblazeb2.com";
              PDS_BLOBSTORE_S3_FORCE_PATH_STYLE = "true";
            };

          };

        };

      };

  };

}
