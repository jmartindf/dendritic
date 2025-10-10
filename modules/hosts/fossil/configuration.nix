#  nix build .#.nixosConfigurations.fossil.config.system.build.isoImage
#  nix run github:nix-community/nixos-generators -- -f proxmox-lxc --system x86_64-linux --flake .#fossil
{
  config,
  inputs,
  ...
}:
let
  defaultUser = config.desertflood.users.users.joe;

  hostInfo = {
    hostName = "fossil";
    domain = "home.thosemartins.family";
    live = false;
    remote = false;
  };

  mTLS-required = false;
in
{
  desertflood.hosts.hosts.fossil = hostInfo;

  flake.modules.nixos.fossil =
    { config, pkgs, ... }:
    let
      nixOScfg = config;
      svcConfig = nixOScfg.services;
      inherit (hostInfo) hostName;
      inherit (nixOScfg.desertflood.networking) webHost;
    in
    {
      imports = [
        inputs.self.modules.nixos.base
        inputs.self.modules.nixos.base-server
        inputs.self.modules.nixos.grafana
        inputs.self.modules.nixos.prometheus
        inputs.self.modules.nixos.proxmox-lxc
      ];

      desertflood = {
        inherit defaultUser hostInfo;

        step-ca.certs.${hostName}.availableTo = { };

        services = {

          traefik = {
            enable = true;
            domain = "${webHost}";

            letsencrypt = {
              enable = true;
              acme-dns = true;
              tailscaleCerts = true;
              defaultResolver = "tailscale";
            };

            rules = {

              app-grafana = {
                http = {
                  routers.grafana-rtr = {
                    entrypoints = "websecure";
                    rule = "Host(`${webHost}`) && PathPrefix(`/grafana`)";
                    service = "grafana-svc";
                    middlewares = "chain-no-auth@file";
                    tls.certResolver = "tailscale";
                  };
                  services.grafana-svc.loadBalancer.servers = [
                    {
                      url = "http://${toString svcConfig.grafana.settings.server.http_addr}:${toString svcConfig.grafana.settings.server.http_port}";
                    }
                  ];
                };
              };

              app-prometheus = {
                http = {
                  routers.prometheus-rtr = {
                    entrypoints = "websecure";
                    rule = "Host(`${webHost}`) && PathPrefix(`/prometheus`)";
                    service = "prometheus-svc";
                    middlewares = "chain-no-auth@file";
                    tls.certResolver = "tailscale";
                  };
                  services.prometheus-svc.loadBalancer.servers = [
                    {
                      url = "https://${toString svcConfig.prometheus.listenAddress}:${toString svcConfig.prometheus.port}";
                    }
                  ];
                };
              };

            };
          };

          prometheus = {
            inherit mTLS-required;

            exporters.node.mTLS-required = mTLS-required;

            monitorHosts = [
              "everest.manticore-mark.ts.net"
              "firewalla.manticore-mark.ts.net"
              "hermes.manticore-mark.ts.net"
              "mark.manticore-mark.ts.net"
              "masto-es.manticore-mark.ts.net"
              "mastodon.manticore-mark.ts.net"
              "underworld.manticore-mark.ts.net"
            ];

            monitorHostsSecure = [
              "127.0.0.1"
              "richard.manticore-mark.ts.net"
              "france.manticore-mark.ts.net"
            ];
          };

        };

      };

      networking = {
        inherit (hostInfo) hostName domain;
      };

      age.rekey.hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDJagbKOnqDYTIZSWnRnMXqSANNeK0KJ+fs6xMhJH6dW";

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
