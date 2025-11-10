_: {
  flake.modules.nixos.france =
    { config, pkgs, ... }:
    let
      nixOScfg = config;
    in
    {
      age.secrets.basic_auth = {
        rekeyFile = ./basic_auth.age;
      };

      age.secrets.caddy-aws-credentials = {
        rekeyFile = ./aws-credentials.age;
        path = "/var/lib/caddy/.aws/credentials";
        symlink = true;
        name = "credentials";
        mode = "0600";
        owner = "caddy";
        group = "caddy";
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
                  order cache before reverse_proxy

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

                  filesystem s3static s3 {
                    region "us-west-001"
                    bucket "desertflood-all-static-sites"
                    endpoint "https://s3.us-west-001.backblazeb2.com/"
                    use_path_style
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

                      root * {args[1]}

                      try_files {path} {path}/ {path}/index.html
                      header @no_ext ?Content-Type text/html

                      file_server {
                        fs s3static
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
                '';

            };
          };

      };
    };
}
