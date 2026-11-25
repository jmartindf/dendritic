# SPDX-FileCopyrightText: 2025 Joe Martin <joe@desertflood.com>
# SPDX-License-Identifier: BlueOak-1.0.0
_: {

  df.services.traefik.nixos =
    {
      host,
      config,
      lib,
      ...
    }:
    let
      cfg = config;
      traefikCfg = config.services.traefik;
      myTraefikCfg = config.desertflood.services.traefik;
      leCfg = config.desertflood.services.traefik.letsencrypt;
      traefikUser = "traefik";
    in
    {
      age.secrets = {
        acme-dns-traefik-json = {
          rekeyFile = ../acme-dns.json.age;
          owner = traefikUser;
          inherit (traefikCfg) group;
        };
      };

      systemd.services.traefik.environment = lib.mkIf leCfg.acme-dns {
        LEGO_DISABLE_CNAME_SUPPORT = "false";
        ACME_DNS_API_BASE = "https://auth.desertflood.com/";
        ACME_DNS_STORAGE_PATH = cfg.age.secrets.acme-dns-traefik-json.path;
      };

      services.traefik.staticConfigOptions.certificatesResolvers.dns-acme-dns.acme =
        lib.mkIf (myTraefikCfg.letsencrypt.enable && myTraefikCfg.letsencrypt.acme-dns)
          {
            email = "${host.desertflood.defaultUser.emails.desertflood.email}";

            caServer =
              if leCfg.production then
                "https://acme-v02.api.letsencrypt.org/directory"
              else
                "https://acme-staging-v02.api.letsencrypt.org/directory";

            storage = "${traefikCfg.dataDir}/acme-dns-${
              if leCfg.production then "" else "staging-"
            }certificates.json";

            dnsChallenge = {
              provider = "acme-dns";

              resolvers = [
                "1.1.1.1:53"
                "1.0.0.1:53"
              ];

              propagation = {
                disableChecks = false;
              };
            };
          };
    };
}
