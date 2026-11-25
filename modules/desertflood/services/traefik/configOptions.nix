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
      leCfg = myTraefikCfg.letsencrypt;

      localIPs = [
        "127.0.0.1/32"
        "10.0.0.0/8"
        "192.168.0.0/16"
        "172.16.0.0/12"
      ];

      tailscaleIPs = [ "100.64.0.0/10" ];

      cloudflareIPs = [
        "173.245.48.0/20"
        "103.21.244.0/22"
        "103.22.200.0/22"
        "103.31.4.0/22"
        "141.101.64.0/18"
        "108.162.192.0/18"
        "190.93.240.0/20"
        "188.114.96.0/20"
        "197.234.240.0/22"
        "198.41.128.0/17"
        "162.158.0.0/15"
        "104.16.0.0/13"
        "104.24.0.0/14"
        "172.64.0.0/13"
        "131.0.72.0/22"
      ];
    in
    {
      services.traefik = {
        staticConfigOptions = {

          global = {
            checkNewVersion = true;
            sendAnonymousUsage = true;
          };

          entryPoints = {

            web = {
              address = ":80";

              http.redirections.entryPoint = {
                to = "websecure";
                scheme = "https";
                permanent = true;
              };
            };

            websecure = {
              address = ":443";

              http = {
                tls = {
                  certResolver = lib.mkIf myTraefikCfg.letsencrypt.enable leCfg.defaultResolver;
                  options = "intermediate@file";
                };
              };

              http3 = { };

              forwardedHeaders = {
                trustedIPs = localIPs;
                # trustedIPs = localIPs ++ tailscaleIPs;
              };

              transport = {
                respondingTimeouts.readTimeout = 900;
              };

            };
          };

          serversTransport.insecureSkipVerify = false;

          log.level = "WARN"; # (Default: error) DEBUG, INFO, WARN, ERROR, FATAL, PANIC

          accessLog = {
            bufferingSize = 100; # buffer 100 lines
            filters.statusCodes = [
              "227-299"
              "400-499"
              "500-599"
            ];
          };

          providers.file = {
            directory = "${myTraefikCfg.dynamicConfigDir}";
            watch = true;
          };

        };

        dynamicConfigOptions = {

          http.serversTransports.skipVerify = {
            insecureSkipVerify = true;
          };

          tls.options = {
            # generated 2025-10-10, Mozilla Guideline v5.6, Traefik 3.3.6, intermediate config
            # https://ssl-config.mozilla.org/#server=traefik&version=3.3.6&config=intermediate&guideline=5.6
            intermediate = {
              minVersion = "VersionTLS12";
              sniStrict = true;

              cipherSuites = [
                "TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256"
                "TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256"
                "TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384"
                "TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384"
                "TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305"
                "TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305"
              ];

              curvePreferences = [
                "X25519"
                "CurveP256"
                "CurveP384"
              ];
            };
          };
        };
      };
    };
}
