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
    in
    {
      # https://github.com/quic-go/quic-go/wiki/UDP-Buffer-Sizes
      boot.kernel.sysctl."net.core.rmem_max" = lib.mkDefault 2500000;
      boot.kernel.sysctl."net.core.wmem_max" = lib.mkDefault 2500000;

      networking.firewall.allowedTCPPorts = [
        80
        443
      ];

      systemd.services.traefik = {
        serviceConfig.ReadOnlyPaths = lib.singleton "${myTraefikCfg.dynamicConfigDir}";
      };
    };
}
