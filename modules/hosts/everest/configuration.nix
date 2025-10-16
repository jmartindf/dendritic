#  nix build .#.nixosConfigurations.everest.config.system.build.isoImage
{
  config,
  inputs,
  lib,
  ...
}:
let
  defaultUser = config.desertflood.users.users.joe;

  hostInfo = {
    hostName = "everest";
    domain = "df.fyi";
    live = true;
    remote = true;
  };

  mTLS-required = false;
in
{
  desertflood.hosts.hosts.everest = hostInfo;

  flake.modules.nixos.everest =
    { config, pkgs, ... }:
    let
      nixOScfg = config;
      svcConfig = nixOScfg.services;
      inherit (hostInfo) hostName;
      inherit (nixOScfg.desertflood.networking) webHost tailscaleDomain;
    in
    {
      imports = [
        inputs.self.modules.nixos.base
        inputs.self.modules.nixos.base-server
        inputs.self.modules.nixos.hetzner-cloud
        { config.facter.reportPath = ./facter.json; }
        inputs.self.modules.nixos.dockeras
        inputs.self.modules.nixos.lldap
        inputs.self.modules.nixos.step-ca
        inputs.self.modules.nixos.authelia
      ];

      desertflood = {
        inherit defaultUser hostInfo;

        networking = {
          webDomain = "df.fyi";

          services = {
            lldap = {
              protocol = "https";
              domain = "desertflood.link";
              hostName = "lldap";
              path = "";
            };
          };

        };

        step-ca = {
          # configure client certificates
          certs.${hostName}.availableTo = { };
        };

        services = {
          lldap.enable = true;
          redis.enable = true;

          step-ca = {
            # run ca-server
            enable = true;
            fqdns = [ "pki.desertflood.link" ];
          };

          authelia.enable = true;

          traefik = {
            enable = true;

            domain = nixOScfg.desertflood.networking.tsFQDN;

            letsencrypt = {
              enable = true;
              tailscaleCerts = true;
              production = true;
              defaultResolver = "tailscale";
              acme-dns = true;
            };

            rules = {

              smallstep.tcp = {
                routers.smallstep-rtr = {
                  entrypoints = "websecure";
                  service = "smallstep-svc";
                  tls.passthrough = true;
                  rule = "HostSNI(`pki.desertflood.link`)";
                };

                services.smallstep-svc.loadbalancer.servers = [ { address = "127.0.0.1:8443"; } ];
              };

              lldap.http = {

                routers.lldap-rtr = {
                  entrypoints = "websecure";
                  tls.certresolver = "web";
                  rule = "Host(`lldap.desertflood.link`)";
                  middlewares = "chain-no-auth@file";
                  service = "lldap-svc";
                };

                services.lldap-svc.loadbalancer.servers = [ { url = "http://127.0.0.1:17170"; } ];
              };

              authelia.http = {

                routers.authelia-rtr = {
                  entrypoints = "websecure";
                  tls.certresolver = "web";
                  rule = "Host(`idm.thosemartins.family`) || Host(`idm.desertflood.link`) || Host(`idm.df.fyi`)";
                  middlewares = "chain-no-auth@file";
                  service = "authelia-svc";
                };

                services.authelia-svc.loadbalancer.servers = [ { url = "http://127.0.0.1:9091"; } ];
              };
            };

          };
        };
      };

      networking = {
        inherit (hostInfo) hostName domain;

        enableIPv6 = true;

        interfaces.enp1s0.ipv6 = {

          addresses = [
            {
              address = "2a01:4ff:1f0:c8c::1";
              prefixLength = 64;
            }
          ];

          routes = [
            {
              address = "::";
              prefixLength = 0;
              via = "fe80::1";
            }
          ];

        };
      };

      # Save port 22 for Endlessh?
      services.openssh.ports = [
        45897
        22
      ]; # from `uv run --with port4me python -m port4me --tool=ssh --user everest`

      age.rekey.hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEuOqBBSAsZYRTXSZmT5InXA2XbI6ciRtESNcXHJxGij";

      nix.settings.trusted-users = [ "nixos" ];

      users.users = {

        nixos = {
          isNormalUser = true;
          extraGroups = [ "wheel" ];
          openssh.authorizedKeys.keys = defaultUser.authorizedKeys;
        };

        root = {
          openssh.authorizedKeys.keys = defaultUser.authorizedKeys;
        };

      };

    };
}
