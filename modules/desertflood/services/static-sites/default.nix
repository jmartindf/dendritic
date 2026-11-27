# SPDX-FileCopyrightText: 2025 Joe Martin <joe@desertflood.com>
# SPDX-License-Identifier: BlueOak-1.0.0
{
  df,
  ...
}:
{
  df.services.static-sites = {

    includes = [
      df.services.webserv
    ];

    traefik-routers = {
      sites-static = {
        rule = "Host(`voxduo.com`) || Host(`files.voxduo.com`) || Host(`pluribus.voxduo.com`) || Host(`jmartindf.com`)";
        service = "sites-static-svc@file";
        middlewares = "chain-no-auth@file";
        certresolver = "web";
      };
    };

    nixos = {

      desertflood.services.caddy.settings = {
        site-blocks = # caddy
          ''
            import local-static voxduo.com voxduo
            import local-static files.voxduo.com voxduo-files
            import local-static pluribus.voxduo.com voxduo-pluribus
            import local-static jmartindf.com jmartindf
          '';
      };

    };
  };
}
