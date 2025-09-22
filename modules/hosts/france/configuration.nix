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
    { config, pkgs, ... }:
    let
      nixOScfg = config;
      svcConfig = nixOScfg.services;
      inherit (hostInfo) hostName;
      inherit (nixOScfg.desertflood.networking) webHost tailscaleDomain;
    in
    {
      imports = [
        inputs.self.modules.nixos.apprise-api
        inputs.self.modules.nixos.base
        inputs.self.modules.nixos.base-server
        inputs.self.modules.nixos.grafana
        inputs.self.modules.nixos.ntfy
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

      age.secrets.basic_auth = {
        rekeyFile = ./basic_auth.age;
      };

      systemd.services.caddy.serviceConfig = {
        EnvironmentFile = nixOScfg.age.secrets.basic_auth.path;
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

          };

        };

        step-ca.certs.${hostName}.availableTo = { };

        services = {

          apprise-api = {
            enable = true;
            log-level = "INFO";
          };

          ntfy.enable = true;

          caddy = {
            enable = true;

            letsencrypt = {
              enable = true;
              acme-dns = true;
              production = true;
            };

            settings = {

              site-blocks = # caddy
                ''
                  ${nixOScfg.networking.hostName}.${nixOScfg.desertflood.networking.tailscaleDomain} {
                    reverse_proxy /prometheus* https://${toString svcConfig.prometheus.listenAddress}:${toString svcConfig.prometheus.port}
                  }

                  *.desertflood.com {
                    import challenge_dns_acme-dns

                    @monitor host monitor.desertflood.com
                    handle @monitor {
                      reverse_proxy /grafana* http://${toString svcConfig.grafana.settings.server.http_addr}:${toString svcConfig.grafana.settings.server.http_port}
                    }

                    @taskchamp host taskchamp.desertflood.com
                    handle @taskchamp {
                      reverse_proxy http://${toString svcConfig.taskchampion-sync-server.host}:${toString svcConfig.taskchampion-sync-server.port}
                    }

                    @ntfy-sh host ntfy.desertflood.com
                    handle @ntfy-sh {
                      reverse_proxy http://${toString svcConfig.ntfy-sh.settings.listen-http}

                      # Redirect HTTP to HTTPS, but only for GET topic addresses, since we want
                      # it to work with curl without the annoying https:// prefix
                      # https://docs.ntfy.sh/config/#nginxapache2caddy
                      @httpget {
                        protocol http
                        method GET
                        path_regexp ^/([-_a-z0-9]{0,64}$|docs/|static/)
                      }
                      redir @httpget https://{host}{uri}
                    }

                    @apprise-api host apprise.desertflood.com
                    handle @apprise-api {
                      handle_path /s/* {
                        root ${pkgs.local.apprise-api}/webapp/static
                        file_server
                      }
                      reverse_proxy http://${toString nixOScfg.desertflood.services.apprise-api.host}:${toString nixOScfg.desertflood.services.apprise-api.port}
                      basic_auth {
                        {$HTTP_BASIC_AUTH_USER} {$HTTP_BASIC_AUTH_PASSWORD}
                      }
                    }

                    handle {
                      abort
                    }
                  }
                '';

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
              "fossil.manticore-mark.ts.net"
              "richard.manticore-mark.ts.net"
            ];
          };
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
