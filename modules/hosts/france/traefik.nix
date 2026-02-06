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
              # {
              #   main = "df.fyi";
              #   sans = [ "*.df.fyi" ];
              # }
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

              service-caddy = {
                http.services.sites-static-svc.loadBalancer.servers = [
                  {
                    url = "http://127.0.0.1:${toString dfCfg.globals.ports.caddy-static}";
                  }
                ];
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
                    service = "sites-static-svc@file";
                    middlewares = "chain-basic-auth@file";
                  };
                  services.apprise-svc.loadBalancer.servers = [
                    {
                      url = "http://${toString dfCfg.services.apprise-api.host}:${toString dfCfg.services.apprise-api.port}";
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

              sites-static = {
                http = {
                  routers.sites-static-rtr = {
                    entrypoints = "websecure";
                    rule = "Host(`voxduo.com`) || Host(`files.voxduo.com`) || Host(`pluribus.voxduo.com`) || Host(`jmartindf.com`)";
                    service = "sites-static-svc@file";
                    middlewares = "chain-no-auth@file";
                    tls.certresolver = "web";
                  };
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

              app-sftpgo = {
                http = {
                  routers.sftpgo-rtr =
                    let
                      uri = dfCfg.networking.services.sftpgo;
                    in
                    {
                      entrypoints = "websecure";
                      rule = "Host(`${uri.fqdn}`) && PathPrefix(`${uri.path}`)";
                      service = "sftpgo-svc";
                      tls.certresolver = "web";
                    };
                  services.sftpgo-svc.loadBalancer.servers = [
                    {
                      url = "http://127.0.0.1:${toString dfCfg.services.sftpgo.port}";
                    }
                  ];
                };
              };

              app-loki = {
                http = {
                  routers.loki-rtr =
                    let
                      uri = dfCfg.networking.services.loki;
                    in
                    {
                      entrypoints = "websecure";
                      rule = "Host(`${uri.fqdn}`) && PathPrefix(`${uri.path}`)";
                      service = "loki-svc";
                      tls.certresolver = "tailscale";
                    };
                  services.loki-svc.loadBalancer.servers = [
                    {
                      url = "http://127.0.0.1:${toString dfCfg.services.loki.port}";
                    }
                  ];
                };
              };

              app-linkwarden = {
                http = {
                  routers.linkwarden-rtr =
                    let
                      uri = dfCfg.networking.services.linkwarden;
                    in
                    {
                      entrypoints = "websecure";
                      rule = "Host(`${uri.fqdn}`)";
                      service = "linkwarden-svc";
                      tls.certresolver = "web";
                    };
                  services.linkwarden-svc.loadBalancer.servers = [
                    {
                      url = "http://127.0.0.1:${toString nixOScfg.services.linkwarden.port}";
                    }
                  ];
                };
              };

              app-acme-dns = {
                http = {
                  routers.acme-dns-rtr =
                    let
                      uri = dfCfg.networking.services.acme-dns;
                    in
                    {
                      entrypoints = "websecure";
                      rule = "Host(`${uri.fqdn}`)";
                      service = "acme-dns-svc";
                      tls.certresolver = "web";
                    };
                  services.acme-dns-svc.loadBalancer.servers = [
                    {
                      url = "http://127.0.0.1:${toString nixOScfg.desertflood.globals.ports.acme-dns}";
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
