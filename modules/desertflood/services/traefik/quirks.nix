# SPDX-FileCopyrightText: 2025 Joe Martin <joe@desertflood.com>
# SPDX-License-Identifier: BlueOak-1.0.0
{ lib, ... }:
let
  appRules = apps: lib.attrsets.concatMapAttrs buildAppRule (lib.mergeAttrsList apps);

  buildAppRule = app: details: {
    "app-${app}" = {
      http = {
        routers."${app}-rtr" = {
          entrypoints = "websecure";
          inherit (details) rule;
          service = "${app}-svc";
          ${if details ? certresolver then "tls" else null} = {
            inherit (details) certresolver;
          };
          ${if details ? middlewares then "middlewares" else null} = details.middlewares;
        };
        services."${app}-svc".loadBalancer.servers = [
          {
            inherit (details) url;
          }
        ];
      };
    };
  };
in
{
  den.quirks.traefik-apps = {
    description = "Traefik 'rule' for a service";
  };

  df.services.traefik.nixos =
    {
      traefik-apps,
      ...
    }:
    {
      config = {
        desertflood.services.traefik.rules = appRules traefik-apps;
      };
    };
}
