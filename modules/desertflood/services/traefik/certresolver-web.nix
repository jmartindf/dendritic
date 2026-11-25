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
      traefikCfg = config.services.traefik;
      myTraefikCfg = config.desertflood.services.traefik;
      leCfg = config.desertflood.services.traefik.letsencrypt;
    in
    {

      services.traefik.staticConfigOptions.certificatesResolvers =
        lib.mkIf myTraefikCfg.letsencrypt.enable
          {
            web.acme = {
              email = "${host.desertflood.defaultUser.emails.desertflood.email}";

              caServer =
                if leCfg.production then
                  "https://acme-v02.api.letsencrypt.org/directory"
                else
                  "https://acme-staging-v02.api.letsencrypt.org/directory";

              storage = "${traefikCfg.dataDir}/webresolver-${
                if leCfg.production then "" else "staging-"
              }certificates.json";

              httpChallenge.entryPoint = "web";
            };
          };
    };
}
