_: {
  flake.modules.nixos.france =
    { config, ... }:
    let
      nixOScfg = config;
      svcConfig = nixOScfg.services;
      dfCfg = nixOScfg.desertflood;
      webHostTailscale = "${nixOScfg.networking.hostName}.${dfCfg.networking.tailscaleDomain}";
    in
    {
      desertflood = {

        services = {

          traefik = {
            enable = true;

            domains = [
              {
                main = "desertflood.com";
                sans = [ "*.desertflood.com" ];
              }
              {
                main = "pds.wordflood.net";
                sans = [ "*.pds.wordflood.net" ];
              }
            ];

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
                      url = "http://127.0.0.1:${toString dfCfg.services.attic.port}";
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
                      url = "http://${toString dfCfg.services.apprise-api.host}:${toString dfCfg.services.apprise-api.port}";
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
                    rule = "Host(`${dfCfg.networking.services.lubelogger.fqdn}`)";
                    service = "lubelogger-svc";
                    middlewares = "chain-no-auth@file";
                    tls.certresolver = "web";
                  };
                  services.lubelogger-svc.loadBalancer.servers = [
                    {
                      url = "http://127.0.0.1:${toString dfCfg.services.lubelogger.port}";
                    }
                  ];
                };
              };

              site-voxduo = {
                http = {
                  routers.voxduo-rtr = {
                    entrypoints = "websecure";
                    rule = "Host(`voxduo.com`)";
                    service = "voxduo-svc";
                    middlewares = "chain-no-auth@file";
                    tls.certresolver = "web";
                  };
                  services.voxduo-svc.loadBalancer.servers = [
                    {
                      url = "http://127.0.0.1:10535";
                    }
                  ];
                };
              };

              site-voxduo-files = {
                http = {
                  routers.voxfiles-rtr = {
                    entrypoints = "websecure";
                    rule = "Host(`files.voxduo.com`)";
                    service = "voxfiles-svc";
                    middlewares = "chain-no-auth@file";
                    tls.certresolver = "web";
                  };
                  services.voxfiles-svc.loadBalancer.servers = [
                    {
                      url = "http://127.0.0.1:10535";
                    }
                  ];
                };
              };

              site-voxduo-pluribus = {
                http = {
                  routers.voxpluribus-rtr = {
                    entrypoints = "websecure";
                    rule = "Host(`pluribus.voxduo.com`)";
                    service = "voxpluribus-svc";
                    middlewares = "chain-no-auth@file";
                    tls.certresolver = "web";
                  };
                  services.voxpluribus-svc.loadBalancer.servers = [
                    {
                      url = "http://127.0.0.1:10535";
                    }
                  ];
                };
              };

              app-linkding = {
                http = {
                  routers.linkding-rtr = {
                    entrypoints = "websecure";
                    rule = "Host(`${dfCfg.networking.services.linkding.fqdn}`)";
                    service = "linkding-svc";
                    middlewares = "chain-no-auth@file";
                    tls.certresolver = "web";
                  };
                  services.linkding-svc.loadBalancer.servers = [
                    {
                      url = "http://127.0.0.1:${toString dfCfg.services.linkding.port}";
                    }
                  ];
                };
              };

              app-bsky-pds = {
                http = {
                  routers.bsky-pds-rtr = {
                    entrypoints = "websecure";
                    rule = "Host(`pds.wordflood.net`) || HostRegexp(`^.+\.pds\.wordflood\.net$`)";
                    service = "bsky-pds-svc";
                  };
                  services.bsky-pds-svc.loadBalancer.servers = [
                    {
                      url = "http://127.0.0.1:${toString dfCfg.services.bluesky-pds.port}";
                    }
                  ];
                };
              };

            };
          };
        };
      };

    };
}
