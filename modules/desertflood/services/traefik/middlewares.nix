# SPDX-FileCopyrightText: 2025 Joe Martin <joe@desertflood.com>
# SPDX-License-Identifier: BlueOak-1.0.0
_: {

  df.services.traefik.nixos =
    {
      config,
      ...
    }:
    let
      cfg = config;
      myTraefikCfg = config.desertflood.services.traefik;
      traefikUser = "traefik";
    in
    {
      config = {
        age.secrets.traefik_basic-auth_credentials = {
          rekeyFile = ./basic_auth_credentials.age;
          owner = traefikUser;
          inherit (cfg.services.traefik) group;
        };

        services.traefik.dynamicConfigOptions.http.middlewares = {
          middlewares-basic-auth = {
            basicAuth = {
              usersFile = cfg.age.secrets.traefik_basic-auth_credentials.path;
              realm = "Traefik 3 Basic Auth";
              removeHeader = true;
            };
          };

          middlewares-authelia = {
            forwardAuth = {
              address = myTraefikCfg.forwardAuthURL;
              trustForwardHeader = true;
              authResponseHeaders = [
                "Remote-User"
                "Remote-Groups"
                "Remote-Name"
                "Remote-Email"
              ];
            };
          };

          middlewares-compress = {
            compress = { };
          };

          middlewares-contenttype = {
            contentType = { };
          };

          middlewares-rate-limit = {
            rateLimit = {
              average = 100;
              burst = 150;
              period = "1s";
            };
          };

          middlewares-secure-headers = {
            headers = {
              # accessControlAllowMethods = [
              #   "GET"
              #   "OPTIONS"
              #   "PUT"
              # ];

              # accessControlMaxAge = 100;
              hostsProxyHeaders = [ "X-Forwarded-Host" ];
              # stsSeconds = 63072000;
              # stsIncludeSubdomains = true;
              # stsPreload = true;
              # customFrameOptionsValue = "SAMEORIGIN"; # https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/X-Frame-Options
              contentTypeNosniff = true;
              browserXssFilter = true;
              referrerPolicy = "same-origin";
              permissionsPolicy = "camera=(), microphone=(), geolocation=(), payment=(), usb=(), vr=()";

              customResponseHeaders = {
                X-Robots-Tag = "none,noarchive,nosnippet,notranslate,noimageindex,"; # disable search engines from indexing server
                server = ""; # hide server info from visitors
              };
            };
          };

          chain-authelia = {
            chain.middlewares = [
              "middlewares-rate-limit"
              "middlewares-authelia"
              "middlewares-contenttype"
              "middlewares-secure-headers"
              "middlewares-compress"
            ];
          };

          chain-basic-auth = {
            chain.middlewares = [
              "middlewares-rate-limit"
              "middlewares-basic-auth"
              "middlewares-contenttype"
              "middlewares-secure-headers"
              "middlewares-compress"
            ];
          };

          chain-no-auth = {
            chain.middlewares = [
              "middlewares-rate-limit"
              "middlewares-contenttype"
              "middlewares-secure-headers"
              "middlewares-compress"
            ];
          };

        };
      };
    };
}
