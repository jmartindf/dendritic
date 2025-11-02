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

        caddy = {
          enable = true;

          letsencrypt = {
            enable = false;
            acme-dns = false;
            tailscaleCerts = false;
            production = true;
          };

          settings = {

            disableSSL = true;

            global = # caddy
              ''
                filesystem s3static s3 {
                  region "us-west-001"
                  bucket "desertflood-all-static-sites"
                  endpoint "https://s3.us-west-001.backblazeb2.com/"
                  use_path_style
                }
              '';

            site-blocks = # caddy
              ''
                http://apprise.desertflood.com:10535 {
                  bind 127.0.0.1
                  log

                  handle_path /s/* {
                    root ${pkgs.local.apprise-api}/webapp/static
                    file_server
                  }
                }

                http://voxduo.com:10535 {
                  bind 127.0.0.1
                  log

                  @no_ext {
                    path_regexp .*\/[^.]+$
                  }

                  root * voxduo

                  try_files {path} {path}/ {path}/index.html
                  header @no_ext ?Content-Type text/html

                  file_server {
                    fs s3static
                    disable_canonical_uris
                  }
                }

                http://files.voxduo.com:10535 {
                  bind 127.0.0.1
                  log

                  @no_ext {
                    path_regexp .*\/[^.]+$
                  }

                  root * voxduo-files

                  try_files {path} {path}/ {path}/index.html
                  header @no_ext ?Content-Type text/html

                  file_server {
                    fs s3static
                    disable_canonical_uris
                  }
                }

                http://pluribus.voxduo.com:10535 {
                  bind 127.0.0.1
                  log

                  @no_ext {
                    path_regexp .*\/[^.]+$
                  }

                  root * voxduo-pluribus

                  try_files {path} {path}/ {path}/index.html
                  header @no_ext ?Content-Type text/html

                  file_server {
                    fs s3static
                    disable_canonical_uris
                  }
                }
              '';

          };
        };

      };
    };
}
