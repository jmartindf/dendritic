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

          caddy = {
            letsencrypt = {
              enable = false;
              acme-dns = false;
              tailscaleCerts = false;
              production = true;
            };

            settings = {
              debug = false;
              disableSSL = true;
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
