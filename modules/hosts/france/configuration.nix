#  nix build .#.nixosConfigurations.france.config.system.build.isoImage
{
  config,
  inputs,
  ...
}:
let
  defaultUser = config.desertflood.users.users.joe;

  hostInfo = {
    hostName = "france";
    domain = "df.fyi";
    live = true;
    remote = true;
  };

  mTLS-required = false;
in
{
  desertflood.hosts.hosts.france = hostInfo;

  flake.modules.nixos.france =
    { config, ... }:
    let
      nixOScfg = config;
      inherit (hostInfo) hostName;
      inherit (nixOScfg.desertflood.networking) tailscaleDomain;
    in
    {
      imports = [
        inputs.self.modules.nixos.base
        inputs.self.modules.nixos.base-server
        inputs.self.modules.nixos.grafana
        inputs.self.modules.nixos.prometheus
        inputs.self.modules.nixos.hetzner-cloud
        { config.facter.reportPath = ./facter.json; }
      ];

      # Attach block storage volume, for Forgejo and others
      disko.devices.disk = {
        block = {
          device = "/dev/disk/by-id/scsi-0HC_Volume_103482293";
          type = "disk";
          content = {
            type = "filesystem";
            format = "ext4";
            mountpoint = "/var";
          };
        };
      };

      desertflood = {
        inherit defaultUser hostInfo;

        networking = {
          webDomain = "df.fyi";

          services = {

            grafana = {
              domain = "desertflood.com";
              hostName = "monitor";
              path = "/grafana/";
            };

            prometheus = {
              domain = tailscaleDomain;
              path = "/prometheus/";
            };

            ntfy = {
              domain = "desertflood.com";
              hostName = "ntfy";
              path = "";
            };

            apprise-api = {
              path = "";
            };

            forgejo = {
              domain = "desertflood.com";
              hostName = "git";
              path = "";
            };

            attic = {
              domain = "desertflood.com";
              hostName = "attic";
              path = "/";
            };

            lubelogger = {
              domain = "thosemartins.family";
              hostName = "lubelogger";
              path = "/";
            };

            linkding = {
              domain = "desertflood.com";
              hostName = "linkding";
              path = "/";
            };

          };

        };

        step-ca.certs.${hostName}.availableTo = { };

        services = {

          crowdsec.enable = true;

          apprise-api = {
            enable = true;
            log-level = "INFO";
          };

          ntfy.enable = true;

          forgejo = {
            enable = true;
            user = "git";
            mode = "prod";
          };

          lubelogger = {
            enable = true;
          };

          linkding = {
            enable = true;
          };

          prometheus = {
            inherit mTLS-required;

            exporters.node.mTLS-required = mTLS-required;

            monitorHosts = [
              "firewalla.manticore-mark.ts.net"
              "hermes.manticore-mark.ts.net"
              "mark.manticore-mark.ts.net"
              "masto-es.manticore-mark.ts.net"
              "mastodon.manticore-mark.ts.net"
              "underworld.manticore-mark.ts.net"
            ];

            monitorHostsSecure = [
              "127.0.0.1"
              "everest.manticore-mark.ts.net"
              "fossil.manticore-mark.ts.net"
              "richard.manticore-mark.ts.net"
            ];
          };

          step-ssh = {
            principals = [
              "git.desertflood.com"
            ];
          };

          attic.enable = true;

        };
      };

      networking = {
        inherit (hostInfo) hostName domain;

        enableIPv6 = true;

        interfaces.enp1s0.ipv6 = {

          addresses = [
            {
              address = "2a01:4ff:1f0:a0b3::1";
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
      ]; # from `uv run --with port4me python -m port4me --tool=ssh --user france`

      services.taskchampion-sync-server = {
        enable = true;
        allowClientIds = [ "5D51EACB-0887-4258-8D84-12B0239E280C" ];
      };

      age.rekey.hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKWvOZ3zQ5zitwbtU1iTa5FjG/47yGqGVoZ7jUg6ouku";

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
