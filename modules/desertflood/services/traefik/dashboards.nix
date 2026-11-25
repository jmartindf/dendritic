# SPDX-FileCopyrightText: 2025 Joe Martin <joe@desertflood.com>
# SPDX-License-Identifier: BlueOak-1.0.0
_: {

  df.services.traefik.nixos =
    {
      host,
      ...
    }:
    {
      config = {
        desertflood.services.traefik = {
          rules = {
            dashboard = {
              http.routers.traefik-rtr = {
                entrypoints = "websecure";
                rule = "Host(`${host.tsFQDN}`) && (PathPrefix(`/traefik/api`) || PathPrefix(`/traefik/dashboard`))";
                service = "api@internal";
                middlewares = "chain-no-auth@file";
                tls.certResolver = "tailscale";
              };
            };

            metrics = {
              http.routers.metrics-rtr = {
                entrypoints = "websecure";
                rule = "Host(`${host.tsFQDN}`) && PathPrefix(`/metrics`)";
                service = "prometheus@internal";
                middlewares = "chain-no-auth@file";
                tls.certResolver = "tailscale";
              };
            };
          };
        };

        services.traefik.staticConfigOptions = {
          api = {
            insecure = false;
            dashboard = true;
            debug = false;
            disabledashboardad = true;
            basepath = "/traefik";
          };

          metrics.prometheus = {
            addEntryPointsLabels = true;
            addServicesLabels = true;
            addRoutersLabels = true;
            manualRouting = true;
          };
        };
      };
    };
}
