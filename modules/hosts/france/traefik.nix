_: {
  den.aspects.france.nixos =
    { config, ... }:
    let
      nixOScfg = config;
      svcConfig = nixOScfg.services;
      dfCfg = nixOScfg.desertflood;
    in
    {
      desertflood.services.traefik = {
        domains = [
          {
            main = "desertflood.com";
            sans = [ "*.desertflood.com" ];
          }
          {
            main = "pds.wordflood.net";
            sans = [ "*.pds.wordflood.net" ];
          }
          {
            main = "thosemartins.family";
            sans = [ "*.thosemartins.family" ];
          }
          {
            main = "df.fyi";
            sans = [ "*.df.fyi" ];
          }
        ];

        letsencrypt = {
          enable = true;
          acme-dns = true;
          tailscaleCerts = true;
          production = true;
          defaultResolver = "dns-acme-dns";
        };

        rules = {

          app-taskchamp = {
            http = {
              routers.taskchamp-rtr = {
                entrypoints = "websecure";
                rule = "Host(`taskchamp.desertflood.com`)";
                service = "taskchamp-svc";
                middlewares = "chain-no-auth@file";
              };
              services.taskchamp-svc.loadBalancer.servers = [
                {
                  url = "http://${toString svcConfig.taskchampion-sync-server.host}:${toString svcConfig.taskchampion-sync-server.port}";
                }
              ];
            };
          };

          app-homeassistant = {
            http = {
              routers.homeassistant-rtr = {
                entrypoints = "websecure";
                rule = "Host(`house.thosemartins.family`)";
                service = "homeassistant-svc";
                middlewares = "chain-no-auth@file";
                # tls.certresolver = "web";
              };
              services.homeassistant-svc.loadBalancer.servers = [
                {
                  url = "http://${dfCfg.globals.tailscaleIPs.homeassistant}:80";
                }
              ];
            };
          };

        };
      };

    };
}
