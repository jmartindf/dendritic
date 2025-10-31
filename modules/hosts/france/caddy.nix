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
              '';

          };
        };

      };
    };
}
