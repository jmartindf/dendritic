{ df, ... }: {
  den.aspects.france = {

    includes = [ df.services.caddy ];

    nixos =
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
              letsencrypt = {
                enable = false;
                acme-dns = false;
                tailscaleCerts = false;
                production = true;
              };

              settings = {

                debug = false;
                disableSSL = true;

                site-blocks = # caddy
                  ''
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
  };
}
