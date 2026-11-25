# SPDX-FileCopyrightText: 2025 Joe Martin <joe@desertflood.com>
# SPDX-License-Identifier: BlueOak-1.0.0
_: {

  df.services.traefik.nixos =
    {
      config,
      lib,
      ...
    }:
    let
      myTraefikCfg = config.desertflood.services.traefik;
      leCfg = config.desertflood.services.traefik.letsencrypt;
      traefikUser = "traefik";
    in
    {
      services.tailscale.permitCertUid = lib.mkIf leCfg.tailscaleCerts traefikUser;

      services.traefik.staticConfigOptions.certificatesResolvers =
        lib.mkIf myTraefikCfg.letsencrypt.enable
          {
            tailscale.tailscale = lib.mkIf leCfg.tailscaleCerts { };
          };
    };
}
