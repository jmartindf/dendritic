# SPDX-FileCopyrightText: 2025 Joe Martin <joe@desertflood.com>
# SPDX-License-Identifier: BlueOak-1.0.0
_: {
  df.services.bluesky-pds =
    # bluesky-pds = {
    #   domain = "wordflood.net";
    #   hostName = "pds";
    #   path = "";
    # };
    let
      pdsHost = "pds.wordflood.net";
    in
    {

      traefik-apps = { host, ... }: {
        bsky-pds = {
          rule = "Host(`${pdsHost}`) || HostRegexp(`^.+\\.pds\\.wordflood\\.net$`)";
          url = "http://127.0.0.1:${toString host.desertflood.globals.ports.bluesky-pds}";
        };
      };

      nixos =
        {
          host,
          pkgs,
          config,
          ...
        }:
        let
          nixOScfg = config;
        in
        {
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
              PDS_HOSTNAME = pdsHost;
              PDS_PORT = host.desertflood.globals.ports.bluesky-pds;
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
}
