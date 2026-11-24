# SPDX-FileCopyrightText: 2025 Joe Martin <joe@desertflood.com>
# SPDX-License-Identifier: BlueOak-1.0.0
{
  df,
  ...
}:
{
  df.services.linkwarden =
    let
      linkwardenHost = "linkwarden.desertflood.com";
      linkwardenPort = 12568; # uv run --with port4me python -m port4me --tool=linkwarden
    in
    {
      # The Nix OS linkwarden module activates PostgreSQL
      includes = [ df.services.postgresql ];

      traefik-apps = {
        linkwarden = {
          rule = "Host(`${linkwardenHost}`)";
          url = "http://127.0.0.1:${toString linkwardenPort}";
          certresolver = "web";
        };
      };

      nixos =
        {
          pkgs,
          config,
          ...
        }:
        let
          nixOScfg = config;
        in
        {

          age.secrets.linkwarden.rekeyFile = ./secrets.env.age;

          services.linkwarden = {
            enable = true;

            port = linkwardenPort;

            package = pkgs.local.linkwarden;

            host = "127.0.0.1";

            environment = {
              NEXT_PUBLIC_DISABLE_REGISTRATION = "true";
              NEXT_PUBLIC_CREDENTIALS_ENABLED = "false";
              NEXT_PUBLIC_EMAIL_PROVIDER = "true";
              EMAIL_FROM = "admin@desertflood.com";
              BASE_URL = "https://${linkwardenHost}/";
              NEXT_PUBLIC_AUTHENTIK_ENABLED = "true";
              AUTHENTIK_CUSTOM_NAME = "authentik Desertflood";
              AUTHENTIK_ISSUER = "https://sso.desertflood.link/application/o/linkwarden";
              NEXTAUTH_URL = "https://${linkwardenHost}/api/v1/auth";

              # Triple the allowed SingleFile uploads (default is 10 MB)
              NEXT_PUBLIC_MAX_FILE_BUFFER = "30";

              # Triple the allowed import file size (default is 10 MB)
              IMPORT_LIMIT = "10";

              # Lean and mean config, for Linkwarden 2.15
              # Limit memory pools
              MALLOC_ARENA_MAX = "2";
              # Cap the app's heap size
              NODE_OPTIONS = "--max-old-space-size=400";
              # preserve one link at a time
              ARCHIVE_TAKE_COUNT = "1";
            };

            environmentFile = "${nixOScfg.age.secrets.linkwarden.path}";
          };

        };
    };
}
