# SPDX-FileCopyrightText: 2025 Joe Martin <joe@desertflood.com>
# SPDX-License-Identifier: BlueOak-1.0.0
_: {
  df.services.acme-dns =
    { host, ... }:
    let
      apiDomain = "desertflood.com";
      apiPort = host.desertflood.globals.ports.acme-dns;
      inherit (host.desertflood.globals.publicIPs.france) ip4;

    in
    {

      traefik-apps = {
        acme-dns = {
          rule = "Host(`auth.${apiDomain}`)";
          url = "http://127.0.0.1:${toString apiPort}";
          certresolver = "web";
        };
      };

      nixos =
        {
          lib,
          pkgs,
          ...
        }:
        {
          options.services.acme-dns.settings.database.engine = lib.mkOption {
            type = lib.types.enum [
              "sqlite"
              "postgres"
            ];
          };

          config = {
            services.acme-dns = {

              enable = true;
              package = pkgs.local.acme-dns;

              settings = {

                general = {

                  records = [
                    "auth.${apiDomain}. A ${ip4}"
                    # "auth.${baseDomain}. AAAA ${ip6}"
                    "auth.${apiDomain}. NS auth.${apiDomain}."
                    "auth.${apiDomain}. CAA 0 issue \"letsencrypt.org\""
                    "auth.${apiDomain}. CAA 0 issuewild \"letsencrypt.org\""
                  ];

                  protocol = "both";
                  nsname = "auth.${apiDomain}";
                  nsadmin = "admin.${apiDomain}";
                  listen = "${ip4}:53";
                  domain = "auth.${apiDomain}";
                };

                database.engine = "sqlite";

                api = {
                  tls = "none";
                  ip = "127.0.0.1";
                  port = apiPort;
                };
              };
            };

            networking.firewall = {
              allowedTCPPorts = [
                53
              ];
              allowedUDPPorts = [ 53 ];
            };

          };
        };
    };
}
