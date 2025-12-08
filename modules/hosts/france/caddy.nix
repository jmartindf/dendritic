_: {
  flake.modules.nixos.france =
    { config, pkgs, ... }:
    let
      nixOScfg = config;
      cacheHTMLDir = nixOScfg.desertflood.globals.paths.cacheHTML;
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

                      root * ${cacheHTMLDir}/{args[1]}

                      try_files {path} {path}/ {path}/index.html
                      header @no_ext ?Content-Type text/html

                      @exists file
                      handle @exists {
                        cache
                        file_server {
                          disable_canonical_uris
                        }
                      }

                      handle {
                        cache
                        s3proxy {
                          root {args[1]}
                          bucket "desertflood-all-static-sites"
                          region "us-west-001"
                          endpoint "https://s3.us-west-001.backblazeb2.com/"
                          force_path_style
                        }
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

                  import local-static voxduo.com voxduo
                  import local-static files.voxduo.com voxduo-files
                  import local-static pluribus.voxduo.com voxduo-pluribus
                  import local-static jmartindf.com jmartindf
                '';

            };

            html-cache = {
              enable = true;

              settings = {
                dataDir = "${cacheHTMLDir}";
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
