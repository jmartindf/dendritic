#  nix build .#.nixosConfigurations.everest.config.system.build.isoImage
{
  den,
  df,
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

  den.hosts.x86_64-linux.everest = {
    description = "NixOS PKI and security host";
    capabilities.docker-server = true;
    users.nixos = { };
  };

  den.aspects = {

    everest = {
      includes = [
        df.base-server
        df.docker-server
      ];

      nixos =
        { config, pkgs, ... }:
        let
          nixOScfg = config;
          svcConfig = nixOScfg.services;
          inherit (hostInfo) hostName;
          inherit (nixOScfg.desertflood.networking) webHost tailscaleDomain;
        in
        {
          imports = [
            inputs.self.modules.nixos.hetzner-cloud
            { config.facter.reportPath = ./facter.json; }
            inputs.self.modules.nixos.step-ca
          ];

          desertflood = {
            inherit defaultUser hostInfo;

            networking = {
              webDomain = "df.fyi";
            };

            step-ca = {
              # configure client certificates
              certs.${hostName}.availableTo = { };
            };

            services = {

              step-ca = {
                # run ca-server
                enable = true;
                fqdns = [ "pki.desertflood.link" ];
              };

              authentik.enable = true;

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

                  authentik.http = {

                    routers.authentik-rtr = {
                      entrypoints = "websecure";
                      tls.certresolver = "web";
                      rule = "Host(`authentik.desertflood.link`) || Host(`sso.desertflood.link`)";
                      middlewares = "chain-no-auth@file";
                      service = "authentik-svc";
                    };

                    services.authentik-svc.loadbalancer = {

                      serversTransport = "skipVerify@file";
                      servers = [ { url = "https://127.0.0.1:9443"; } ];

                    };

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

          users.users = {

            root = {
              openssh.authorizedKeys.keys = defaultUser.authorizedKeys;
            };

          };

        };
    };
  };
}
