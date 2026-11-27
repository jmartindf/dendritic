{ df, ... }: {
  den.aspects.france = { host, ... }: {

    includes = [ df.services.caddy ];

    nixos =
      { config, ... }:
      let
        nixOScfg = config;
        cacheHTMLDir = host.desertflood.globals.paths.cacheHTML;
      in
      {
        age.secrets.b2StaticHTML.rekeyFile = ./rcloneConfig.age;

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
