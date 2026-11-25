# SPDX-FileCopyrightText: 2025 Joe Martin <joe@desertflood.com>
# SPDX-License-Identifier: BlueOak-1.0.0
{ lib, ... }:
let
  appRules = apps: lib.attrsets.concatMapAttrs buildAppRule (lib.mergeAttrsList apps);
  tcpAppRules = apps: lib.attrsets.concatMapAttrs buildTCPAppRule (lib.mergeAttrsList apps);
  routerRules = routers: lib.attrsets.concatMapAttrs buildRouterRule (lib.mergeAttrsList routers);
  serviceRules = services: lib.attrsets.concatMapAttrs buildServiceRule (lib.mergeAttrsList services);

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
        services."${app}-svc".loadBalancer = {
          ${if details ? serversTransport then "serversTransport" else null} = details.serversTransport;
          servers = [
            {
              inherit (details) url;
            }
          ];
        };
      };
    };
  };

  buildRouterRule = router: details: {
    "router-${router}" = {
      http = {
        routers."${router}-rtr" = {
          entrypoints = "websecure";
          inherit (details) rule service;
          ${if details ? certresolver then "tls" else null} = {
            inherit (details) certresolver;
          };
          ${if details ? middlewares then "middlewares" else null} = details.middlewares;
        };
      };
    };
  };

  buildServiceRule = service: details: {
    "service-${service}" = {
      http = {
        services."${service}-svc".loadBalancer.servers = [
          {
            inherit (details) url;
          }
        ];
      };
    };
  };

  buildTCPAppRule = app: details: {
    "app-${app}" = {
      tcp = {
        routers."${app}-rtr" = {
          entrypoints = "websecure";
          inherit (details) rule;
          service = "${app}-svc";
          ${if details ? passthrough then "tls" else null} = {
            inherit (details) passthrough;
          };
          ${if details ? middlewares then "middlewares" else null} = details.middlewares;
        };
        services."${app}-svc".loadBalancer = {
          ${if details ? serversTransport then "serversTransport" else null} = details.serversTransport;
          servers = [
            {
              inherit (details) address;
            }
          ];
        };
      };
    };
  };

in
{
  den.quirks = {
    traefik-apps = {
      description = "Traefik 'rule' for a combined router and service";
    };

    traefik-tcp-apps = {
      description = "Traefik 'rule' for a combined TCP router and service";
    };

    traefik-services = {
      description = "Traefik 'rule' for a standalone service";
    };

    traefik-routers = {
      description = "Traefik 'rule' for a standalone router";
    };
  };

  df.services.traefik.nixos =
    {
      traefik-apps,
      traefik-tcp-apps,
      traefik-routers,
      traefik-services,
      ...
    }:
    {
      config = {
        desertflood.services.traefik.rules =
          (appRules traefik-apps)
          // (tcpAppRules traefik-tcp-apps)
          // (routerRules traefik-routers)
          // (serviceRules traefik-services);
      };
    };
}
