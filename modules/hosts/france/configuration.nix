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
      webHostTailscale = "${nixOScfg.networking.hostName}.${nixOScfg.desertflood.networking.tailscaleDomain}";
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

          traefik = {
            enable = true;
            domain = "desertflood.com";
            extraDomains = [ "*.desertflood.com" ];

            letsencrypt = {
              enable = true;
              acme-dns = true;
              tailscaleCerts = true;
              production = true;
              defaultResolver = "dns-acme-dns";
            };

            rules = {

              app-prometheus = {
                http = {
                  routers.prometheus-rtr = {
                    entrypoints = "websecure";
                    rule = "Host(`${webHostTailscale}`) && PathPrefix(`/prometheus`)";
                    service = "prometheus-svc";
                    middlewares = "chain-no-auth@file";
                    tls.certresolver = "tailscale";
                  };
                  services.prometheus-svc.loadBalancer.servers = [
                    {
                      url = "https://${toString svcConfig.prometheus.listenAddress}:${toString svcConfig.prometheus.port}";
                    }
                  ];
                };
              };

              app-grafana = {
                http = {
                  routers.grafana-rtr = {
                    entrypoints = "websecure";
                    rule = "Host(`monitor.desertflood.com`) && PathPrefix(`/grafana`)";
                    service = "grafana-svc";
                    middlewares = "chain-no-auth@file";
                  };
                  services.grafana-svc.loadBalancer.servers = [
                    {
                      url = "http://${toString svcConfig.grafana.settings.server.http_addr}:${toString svcConfig.grafana.settings.server.http_port}";
                    }
                  ];
                };
              };

              app-taskchamp = {
                http = {
                  routers.taskchamp-rtr = {
                    entrypoints = "websecure";
                    rule = "Host(`taskchamp.desertflood.com`)";
                    service = "taskchamp-svc";
                    middlewares = "chain-no-auth@file";
                  };
                  services.taskchamp-svc.loadBalancer.servers = [
                    {
                      url = "http://${toString svcConfig.taskchampion-sync-server.host}:${toString svcConfig.taskchampion-sync-server.port}";
                    }
                  ];
                };
              };

              app-ntfy = {
                http = {
                  routers.ntfy-rtr = {
                    entrypoints = "websecure";
                    rule = "Host(`ntfy.desertflood.com`)";
                    service = "ntfy-svc";
                    middlewares = "chain-no-auth@file";
                  };
                  services.ntfy-svc.loadBalancer.servers = [
                    {
                      url = "http://${toString svcConfig.ntfy-sh.settings.listen-http}";
                    }
                  ];
                };
              };

              app-attic = {
                http = {
                  routers.attic-rtr = {
                    entrypoints = "websecure";
                    rule = "Host(`attic.desertflood.com`)";
                    service = "attic-svc";
                  };
                  services.attic-svc.loadBalancer.servers = [
                    {
                      url = "http://127.0.0.1:${toString nixOScfg.desertflood.services.attic.port}";
                    }
                  ];
                };
              };

              app-forgejo = {
                http = {
                  routers.forgejo-rtr = {
                    entrypoints = "websecure";
                    rule = "Host(`git.desertflood.com`)";
                    service = "forgejo-svc";
                    middlewares = "chain-no-auth@file";
                  };
                  services.forgejo-svc.loadBalancer.servers = [
                    {
                      url = "http://${toString svcConfig.forgejo.settings.server.HTTP_ADDR}:${toString svcConfig.forgejo.settings.server.HTTP_PORT}";
                    }
                  ];
                };
              };

              app-apprise = {
                http = {
                  routers.apprise-rtr = {
                    entrypoints = "websecure";
                    rule = "Host(`apprise.desertflood.com`)";
                    service = "apprise-svc";
                    middlewares = "chain-basic-auth@file";
                  };
                  routers.apprise-static-rtr = {
                    entrypoints = "websecure";
                    rule = "Host(`apprise.desertflood.com`) && PathPrefix(`/s/`)";
                    service = "apprise-static-svc";
                    middlewares = "chain-basic-auth@file";
                  };
                  services.apprise-svc.loadBalancer.servers = [
                    {
                      url = "http://${toString nixOScfg.desertflood.services.apprise-api.host}:${toString nixOScfg.desertflood.services.apprise-api.port}";
                    }
                  ];
                  services.apprise-static-svc.loadBalancer.servers = [
                    {
                      url = "http://127.0.0.1:10535";
                    }
                  ];
                };
              };

              app-lubelogger = {
                http = {
                  routers.lubelogger-rtr = {
                    entrypoints = "websecure";
                    rule = "Host(`${nixOScfg.desertflood.networking.services.lubelogger.fqdn}`)";
                    service = "lubelogger-svc";
                    middlewares = "chain-no-auth@file";
                    tls.certresolver = "web";
                  };
                  services.lubelogger-svc.loadBalancer.servers = [
                    {
                      url = "http://127.0.0.1:${toString nixOScfg.desertflood.services.lubelogger.port}";
                    }
                  ];
                };
              };

              app-linkding = {
                http = {
                  routers.linkding-rtr = {
                    entrypoints = "websecure";
                    rule = "Host(`${nixOScfg.desertflood.networking.services.linkding.fqdn}`)";
                    service = "linkding-svc";
                    middlewares = "chain-no-auth@file";
                    tls.certresolver = "web";
                  };
                  services.linkding-svc.loadBalancer.servers = [
                    {
                      url = "http://127.0.0.1:${toString nixOScfg.desertflood.services.linkding.port}";
                    }
                  ];
                };
              };

            };
          };

          caddy = {
            enable = true;

            letsencrypt = {
              enable = false;
              acme-dns = false;
              tailscaleCerts = false;
              production = true;
            };

            settings = {

              disableSSL = true;

              site-blocks = # caddy
                ''
                  http://apprise.desertflood.com:10535 {
                    bind 127.0.0.1
                    log

                    handle_path /s/* {
                      root ${pkgs.local.apprise-api}/webapp/static
                      file_server
                    }
                  }
                '';

            };
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
