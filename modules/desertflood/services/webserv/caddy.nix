# SPDX-FileCopyrightText: 2025 Joe Martin <joe@desertflood.com>
# SPDX-License-Identifier: BlueOak-1.0.0
_: {
  df.services.webserv.nixos =
    { host, ... }:
    let
      webFolder = host.desertflood.globals.paths.staticHTML;
      caddyPort = toString host.desertflood.globals.ports.caddy-static;
    in
    {
      # Create a template for caddy, pointing to the folder
      desertflood.services.caddy.settings.snippets = # caddy
        ''
          (local-static) {
            http://{args[0]}:${caddyPort} {
              bind 127.0.0.1
              cache
              log

              @no_ext {
                path_regexp .*\/[^.]+$
              }

              root * ${webFolder}/{args[1]}

              try_files {path} {path}/ {path}/index.html
              header @no_ext ?Content-Type text/html
              file_server {
                disable_canonical_uris
              }
            }
          }
        '';
    };
}
