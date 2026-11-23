_: {
  # SPDX-FileCopyrightText: 2025 Joe Martin <joe@desertflood.com>
  # SPDX-License-Identifier: BlueOak-1.0.0

  df.services.acme-dns.nixos =
    {
      lib,
      pkgs,
      config,
      ...
    }:
    let
      nixOScfg = config;
      dfCfg = nixOScfg.desertflood;
      apiPort = dfCfg.globals.ports.acme-dns;
      inherit (dfCfg.globals.publicIPs.france) ip4;

      baseDomain = "desertflood.com";
    in
    {
      options.services.acme-dns.settings.database.engine = lib.mkOption {
        type = lib.types.enum [
          "sqlite"
          "postgres"
        ];
      };

      config = {
        desertflood.networking.services.acme-dns = { };

        services.acme-dns = {

          enable = true;
          package = pkgs.local.acme-dns;

          settings = {

            general = {

              records = [
                "auth.${baseDomain}. A ${ip4}"
                # "auth.${baseDomain}. AAAA ${ip6}"
                "auth.${baseDomain}. NS auth.${baseDomain}."
                "auth.${baseDomain}. CAA 0 issue \"letsencrypt.org\""
                "auth.${baseDomain}. CAA 0 issuewild \"letsencrypt.org\""
              ];

              protocol = "both";
              nsname = "auth.${baseDomain}";
              nsadmin = "admin.${baseDomain}";
              listen = "${ip4}:53";
              domain = "auth.${baseDomain}";
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
}
