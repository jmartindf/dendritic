# SPDX-FileCopyrightText: 2025 Joe Martin <joe@desertflood.com>
# SPDX-License-Identifier: BlueOak-1.0.0
_: {

  df.services.traefik.nixos =
    {
      config,
      lib,
      ...
    }:
    {
      options.desertflood.services.traefik = {
        letsencrypt = {
          enable = lib.mkEnableOption "using LetsEncrypt for SSL certificates";

          production = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Use the LetsEncrypt production server instead of staging";
          };

          acme-dns = lib.mkEnableOption "Use the acme-dns DNS01 challenge and default accounts for challenges";

          tailscaleCerts = lib.mkEnableOption "Get certificates from Tailscale, for secure HTTP.";

          defaultResolver = lib.mkOption {
            type = lib.types.enum [
              "tailscale"
              "dns-acme-dns"
              "web"
            ];
            default = "web";
            description = "Which certificate resolver to use for the default domain and SANs.";
          };
        };

        domains = lib.mkOption {
          type = lib.types.listOf (
            lib.types.submodule {
              options = {
                main = lib.mkOption {
                  type = lib.types.str;
                  default = null;
                  description = "Main domain name.";
                };
                sans = lib.mkOption {
                  type = lib.types.listOf lib.types.str;
                  default = [ ];
                  description = "List of SANS domain names (Wildcards).";
                };
              };
            }
          );
          default = [ ];
          description = "Domains to use for traefik.";
        };

        domain = lib.mkOption {
          type = lib.types.nullOr lib.types.str;
          default = null;
          description = "What is the main domain name for hosting services";
        };

        extraDomains = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          description = "What alternate domains should be on the main certificate";
        };

        forwardAuthURL = lib.mkOption {
          type = lib.types.str;
          default = null;
          description = "Create a forward auth middleware, using this service";
        };

        dynamicConfigDir = lib.mkOption {
          type = lib.types.str;
          default = null;
          description = "Look here for dynamic configuration in TOML / YAML files";
        };

        rules = lib.mkOption {
          type = lib.types.attrsOf lib.types.anything;
          default = { };
          description = "The name/value pairs to generate as dynamic configuration files";
        };

      };

      config =
        let
          cfg = config;
          traefikCfg = cfg.services.traefik;
          myTraefikCfg = config.desertflood.services.traefik;
        in
        lib.mkMerge [
          {
            desertflood.services.traefik = {

              dynamicConfigDir = lib.mkDefault "/etc/traefik";
              rules.common = traefikCfg.dynamicConfigOptions;

              letsencrypt = {
                enable = lib.mkDefault false;
                production = lib.mkDefault false;
              };

              forwardAuthURL = lib.mkDefault "http://authelia:9091/api/authz/forward-auth";
            };
          }
          (lib.mkIf (myTraefikCfg.domains != [ ]) {
            services.traefik.staticConfigOptions.entryPoints.websecure.http.tls.domains = myTraefikCfg.domains;
          })
          (lib.mkIf (myTraefikCfg.domain != null) {
            services.traefik.staticConfigOptions.entryPoints.websecure.http.tls.domains = [
              {
                main = myTraefikCfg.domain;
                sans = lib.mkIf (myTraefikCfg.extraDomains != [ ]) myTraefikCfg.extraDomains;
              }
            ];
          })
        ];
    };
}
