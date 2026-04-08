#  nix build .#.nixosConfigurations.france.config.system.build.isoImage
{
  den,
  df,
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
    system = "x86_64-linux";
  };

  mTLS-required = false;
in
{
  desertflood.hosts.hosts.${hostInfo.hostName} = hostInfo;

  den.hosts.${hostInfo.system}.${hostInfo.hostName} = {
    description = "NixOS webapp host";
    users.nixos = { };
  };

  den.aspects = {

    ${hostInfo.hostName} = {
      includes = [
        df.base-server
      ];

      nixos =
        {
          config,
          lib,
          pkgs,
          ...
        }:
        let
          nixOScfg = config;
          inherit (hostInfo) hostName;
          inherit (nixOScfg.desertflood.networking) tailscaleDomain;
        in
        {
          imports = [
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

                bluesky-pds = {
                  domain = "wordflood.net";
                  hostName = "pds";
                  path = "";
                };

                sftpgo = {
                  domain = "df.fyi";
                  path = "/sftpgo/";
                };

                linkwarden = {
                  domain = "desertflood.com";
                  hostName = "linkwarden";
                  path = "/";
                };

                acme-dns = {
                  domain = "desertflood.com";
                  hostName = "auth";
                  path = "";
                };

                kosync-dotnet = {
                  domain = "desertflood.com";
                  hostName = "kosync";
                  path = "";
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
                enable = false;
              };

              linkwarden.enable = true;

              prometheus = {
                inherit mTLS-required;

                monitorHosts = [
                  "firewalla.manticore-mark.ts.net"
                  "hermes.manticore-mark.ts.net"
                  "masto-es.manticore-mark.ts.net"
                ];

                monitorHostsSecure = [
                ];
              };

              step-ssh = {
                principals = lib.mkOptionDefault [
                  "git.desertflood.com"
                ];
              };

              attic.enable = true;

              bluesky-pds.enable = true;

              # Implicitly enables SFTPGo
              webserv.enable = true;

              loki.enable = true;
              loki.loglevel = "warn";

              acme-dns.enable = true;

              kosync-dotnet.enable = true;
              kosync-dotnet.trustedProxies = [
                "127.0.0.1"
                "::1"
              ];
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
            package = pkgs.local.taskchampion-sync-server;
            allowClientIds = [ "5D51EACB-0887-4258-8D84-12B0239E280C" ];
          };

          # systemd.services.taskchampion-sync-server.environment = {
          #   RUST_LOG = "debug";
          # };

          age.rekey.hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKWvOZ3zQ5zitwbtU1iTa5FjG/47yGqGVoZ7jUg6ouku";

          users.users = {

            root = {
              openssh.authorizedKeys.keys = defaultUser.authorizedKeys;
            };

          };

        };
    };
  };
}
