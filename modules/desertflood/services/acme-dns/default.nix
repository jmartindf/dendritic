{
  inputs,
  config,
  lib,
  ...
}:
let
  flakeCfg = config;
in
{
  # SPDX-FileCopyrightText: 2025 Joe Martin <joe@desertflood.com>
  # SPDX-License-Identifier: BlueOak-1.0.0

  imports = [ ];

  options = { };

  config = {

    flake.modules.nixos.services =
      {
        lib,
        pkgs,
        config,
        ...
      }:
      let
        nixOScfg = config;
        dfCfg = nixOScfg.desertflood;
        netCfg = dfCfg.networking;
        svcsConfig = dfCfg.services;
        svcsNetCfg = netCfg.services;
        baseDomain = "desertflood.com";
        apiPort = dfCfg.globals.ports.acme-dns;
        inherit (dfCfg.globals.publicIPs.france) ip4 ip6;
      in
      {

        imports = [ ];

        options = {

          desertflood.services.acme-dns = {
            enable = lib.mkEnableOption "Limited DNS server with RESTful HTTP API to handle ACME DNS challenges easily and securely";
          };

          services.acme-dns.settings.database.engine = lib.mkOption {
            type = lib.types.enum [
              "sqlite"
              "postgres"
            ];
          };
        };

        config = lib.mkIf svcsConfig.acme-dns.enable {

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

  };

}
