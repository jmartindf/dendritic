_: {
  flake.modules.nixos.france =
    { config, pkgs, ... }:
    let
      nixOScfg = config;
    in
    {
      age.secrets = {

        basic_auth = {
          rekeyFile = ./basic_auth.age;
        };

        caddy-aws-credentials = {
          rekeyFile = ./aws-credentials.age;
          path = "/var/lib/caddy/.aws/credentials";
          symlink = true;
          name = "credentials";
          mode = "0600";
          owner = "caddy";
          group = "caddy";
        };

        b2StaticHTML.rekeyFile = ./rcloneConfig.age;
      };

      systemd.services.caddy.serviceConfig = {
        EnvironmentFile = nixOScfg.age.secrets.basic_auth.path;
      };

      desertflood.services = {

        caddy =
          let
            caddyPort = toString nixOScfg.desertflood.globals.ports.caddy-static;
          in
          {
            enable = true;

            letsencrypt = {
              enable = false;
              acme-dns = false;
              tailscaleCerts = false;
              production = true;
            };

            settings = {

              debug = false;
              disableSSL = true;

              global = # caddy
                ''
                  order s3proxy before reverse_proxy
                  order cache before s3proxy

                  cache {
                    nuts {
                      path /tmp/nuts/default
                    }

                    storers nuts

                    ttl 1h
                    stale 3h
                    headers Authorization
                    default_cache_control "public, max-age=3600"
                  }

                '';

              site-blocks = # caddy
                ''
                  (b2-static) {
                    http://{args[0]}:${caddyPort} {
                      bind 127.0.0.1
                      cache
                      log

                      @no_ext {
                        path_regexp .*\/[^.]+$
                      }

                      root * /srv/www/html-cache/{args[1]}

                      try_files {path} {path}/ {path}/index.html
                      header @no_ext ?Content-Type text/html
                      file_server {
                        disable_canonical_uris
                      }
                    }
                  }

                  http://apprise.desertflood.com:${caddyPort} {
                    bind 127.0.0.1
                    log
                    cache

                    handle_path /s/* {
                      root ${pkgs.local.apprise-api}/webapp/static
                      file_server
                    }
                  }

                  import b2-static voxduo.com voxduo
                  import b2-static files.voxduo.com voxduo-files
                  import b2-static pluribus.voxduo.com voxduo-pluribus
                  import b2-static jmartindf.com jmartindf
                '';

            };

            html-cache = {
              enable = true;

              settings = {
                dataDir = "/srv/www/html-cache";
                remote = "b2-static:desertflood-all-static-sites";
                rcloneConfFile = nixOScfg.age.secrets.b2StaticHTML.path;

                extraRcloneArgs = [
                  # "--max-size=325K" # download everything for now
                  "--fast-list"
                ];
              };
            };
          };

      };
    };
}
