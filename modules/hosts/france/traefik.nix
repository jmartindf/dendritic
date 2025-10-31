_: {
  flake.modules.nixos.france =
    { config, ... }:
    let
      nixOScfg = config;
      svcConfig = nixOScfg.services;
      webHostTailscale = "${nixOScfg.networking.hostName}.${nixOScfg.desertflood.networking.tailscaleDomain}";
    in
    {
      desertflood = {

        services = {

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
        };
      };

    };
}
