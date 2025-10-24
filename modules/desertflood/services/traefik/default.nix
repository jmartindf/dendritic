{ config, lib, ... }:
let
  flakeCfg = config;
in
{
  flake.modules.nixos.services =
    { config, pkgs, ... }:
    let
      cfg = config;
      myTraefikCfg = config.desertflood.services.traefik;
      leCfg = myTraefikCfg.letsencrypt;

      traefikCfg = cfg.services.traefik;
      traefikUser = "traefik";

      webHostTailscale = "${cfg.networking.hostName}.${cfg.desertflood.networking.tailscaleDomain}";

      toTOML = name: attrSet: (pkgs.formats.toml { }).generate "${name}.toml" attrSet;

      traefikConfigFile = toTOML "config" traefikCfg.staticConfigOptions;
      traefikDynamicConfigFile = toTOML "common" traefikCfg.dynamicConfigOptions;

      generateRules = lib.mapAttrs' (
        ruleName: ruleConfig: {
          name = "traefik/${ruleName}.toml";
          value = {
            source = toTOML ruleName ruleConfig;
          };
        }
      );

      cloudflareIPs = [
        "173.245.48.0/20"
        "103.21.244.0/22"
        "103.22.200.0/22"
        "103.31.4.0/22"
        "141.101.64.0/18"
        "108.162.192.0/18"
        "190.93.240.0/20"
        "188.114.96.0/20"
        "197.234.240.0/22"
        "198.41.128.0/17"
        "162.158.0.0/15"
        "104.16.0.0/13"
        "104.24.0.0/14"
        "172.64.0.0/13"
        "131.0.72.0/22"
      ];

      localIPs = [
        "127.0.0.1/32"
        "10.0.0.0/8"
        "192.168.0.0/16"
        "172.16.0.0/12"
      ];

      tailscaleIPs = [ "100.64.0.0/10" ];
    in
    {
      imports = [ ];

      options.desertflood = {

        services.traefik = {
          enable = lib.mkEnableOption "customized Traefik application router";

          letsencrypt = {
            enable = lib.mkEnableOption "using LetsEncrypt for SSL certificates";

            production = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = "Use the LetsEncrypt production server instead of staging";
            };

            acme-dns = lib.mkEnableOption "Use the acme-dns DNS01 challenge and default accounts for challenges";

            tailscaleCerts = lib.mkEnableOption "Get certificates from Tailscale, for secure HTTP.";

            defaultResolver = lib.mkOption {
              type = lib.types.enum [
                "tailscale"
                "dns-acme-dns"
                "web"
              ];
              default = "web";
              description = "Which certificate resolver to use for the default domain and SANs.";
            };
          };

          domain = lib.mkOption {
            type = lib.types.str;
            default = null;
            description = "What is the main domain name for hosting services";
          };

          extraDomains = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
            description = "What alternate domains should be on the main certificate";
          };

          forwardAuthURL = lib.mkOption {
            type = lib.types.str;
            default = null;
            description = "Create a forward auth middleware, using this service";
          };

          dynamicConfigDir = lib.mkOption {
            type = lib.types.str;
            default = null;
            description = "Look here for dynamic configuration in TOML / YAML files";
          };

          rules = lib.mkOption {
            type = lib.types.attrsOf lib.types.anything;
            default = { };
            description = "The name/value pairs to generate as dynamic configuration files";
          };

        };

      };

      config = lib.mkMerge [
        {
          desertflood.services.traefik = {

            letsencrypt = {
              enable = lib.mkDefault false;
              production = lib.mkDefault false;
            };

            forwardAuthURL = lib.mkDefault "http://authelia:9091/api/authz/forward-auth";

            dynamicConfigDir = lib.mkDefault "/etc/traefik";

            rules = {

              common = traefikCfg.dynamicConfigOptions;

              dashboard = {
                http.routers.traefik-rtr = {
                  entrypoints = "websecure";
                  rule = "Host(`${webHostTailscale}`) && (PathPrefix(`/traefik/api`) || PathPrefix(`/traefik/dashboard`))";
                  service = "api@internal";
                  middlewares = "chain-no-auth@file";
                  tls.certResolver = "tailscale";
                };
              };

              metrics = {
                http.routers.metrics-rtr = {
                  entrypoints = "websecure";
                  rule = "Host(`${webHostTailscale}`) && PathPrefix(`/metrics`)";
                  service = "prometheus@internal";
                  middlewares = "chain-no-auth@file";
                  tls.certResolver = "tailscale";
                };
              };

            };
          };
        }
        (lib.mkIf (myTraefikCfg.domain != null) {
          services.traefik.staticConfigOptions.entryPoints.websecure.http.tls.domains = [
            {
              main = myTraefikCfg.domain;
              sans = lib.mkIf (myTraefikCfg.extraDomains != [ ]) myTraefikCfg.extraDomains;
            }
          ];
        })
        (lib.mkIf myTraefikCfg.enable {

          age.secrets = {
            acme-dns-traefik-json = {
              rekeyFile = ../acme-dns.json.age;
              owner = traefikUser;
              inherit (traefikCfg) group;
            };
            traefik_basic-auth_credentials = {
              rekeyFile = ./basic_auth_credentials.age;
              owner = traefikUser;
              inherit (traefikCfg) group;
            };
          };

          systemd.services.traefik = {
            serviceConfig.ReadOnlyPaths = lib.singleton "${myTraefikCfg.dynamicConfigDir}";

            environment = lib.mkIf leCfg.acme-dns {
              LEGO_DISABLE_CNAME_SUPPORT = "false";
              ACME_DNS_API_BASE = "https://dns01cf.desertflood-s-account.workers.dev/";
              ACME_DNS_STORAGE_PATH = cfg.age.secrets.acme-dns-traefik-json.path;
            };
          };

          # https://github.com/quic-go/quic-go/wiki/UDP-Buffer-Sizes
          boot.kernel.sysctl."net.core.rmem_max" = lib.mkDefault 2500000;
          boot.kernel.sysctl."net.core.wmem_max" = lib.mkDefault 2500000;

          networking.firewall.allowedTCPPorts = [
            80
            443
          ];

          services = {
            tailscale.permitCertUid = lib.mkIf leCfg.tailscaleCerts traefikUser;

            traefik = {

              enable = true;
              package = pkgs.local.traefik;

              staticConfigFile = traefikConfigFile;
              dynamicConfigFile = traefikDynamicConfigFile;

              staticConfigOptions = {

                global = {
                  checkNewVersion = true;
                  sendAnonymousUsage = true;
                };

                entryPoints = {

                  web = {
                    address = ":80";

                    http.redirections.entryPoint = {
                      to = "websecure";
                      scheme = "https";
                      permanent = true;
                    };
                  };

                  websecure = {
                    address = ":443";

                    http = {
                      tls = {
                        certResolver = lib.mkIf myTraefikCfg.letsencrypt.enable leCfg.defaultResolver;
                        options = "intermediate@file";
                      };
                    };

                    http3 = { };

                    forwardedHeaders = {
                      trustedIPs = localIPs;
                    };

                    transport = {
                      respondingTimeouts.readTimeout = 900;
                    };

                  };
                };

                serversTransport.insecureSkipVerify = false;

                log.level = "WARN"; # (Default: error) DEBUG, INFO, WARN, ERROR, FATAL, PANIC

                accessLog = {
                  bufferingSize = 100; # buffer 100 lines
                  filters.statusCodes = [
                    "204-299"
                    "400-499"
                    "500-599"
                  ];
                };

                api = {
                  insecure = false;
                  dashboard = true;
                  debug = false;
                  disabledashboardad = true;
                  basepath = "/traefik";
                };

                metrics.prometheus = {
                  addEntryPointsLabels = true;
                  addServicesLabels = true;
                  addRoutersLabels = true;
                  manualRouting = true;
                };

                certificatesResolvers = lib.mkIf myTraefikCfg.letsencrypt.enable {

                  tailscale.tailscale = lib.mkIf leCfg.tailscaleCerts { };

                  web.acme = {
                    email = "${flakeCfg.desertflood.defaultUser.emails.desertflood.email}";

                    caServer =
                      if leCfg.production then
                        "https://acme-v02.api.letsencrypt.org/directory"
                      else
                        "https://acme-staging-v02.api.letsencrypt.org/directory";

                    storage = "${traefikCfg.dataDir}/webresolver-${
                      if leCfg.production then "" else "staging-"
                    }certificates.json";

                    httpChallenge.entryPoint = "web";
                  };

                  dns-acme-dns.acme = lib.mkIf myTraefikCfg.letsencrypt.acme-dns {
                    email = "${flakeCfg.desertflood.defaultUser.emails.desertflood.email}";

                    caServer =
                      if leCfg.production then
                        "https://acme-v02.api.letsencrypt.org/directory"
                      else
                        "https://acme-staging-v02.api.letsencrypt.org/directory";

                    storage = "${traefikCfg.dataDir}/acme-dns-${
                      if leCfg.production then "" else "staging-"
                    }certificates.json";

                    dnsChallenge = {
                      provider = "acme-dns";

                      resolvers = [
                        "1.1.1.1:53"
                        "1.0.0.1:53"
                      ];

                      propagation = {
                        disableChecks = false;
                      };
                    };

                  };
                };

                providers.file = {
                  directory = "${myTraefikCfg.dynamicConfigDir}";
                  watch = true;
                };

              };

              dynamicConfigOptions = {

                http.serversTransports.skipVerify = {
                  insecureSkipVerify = true;
                };

                tls.options = {
                  # generated 2025-10-10, Mozilla Guideline v5.6, Traefik 3.3.6, intermediate config
                  # https://ssl-config.mozilla.org/#server=traefik&version=3.3.6&config=intermediate&guideline=5.6
                  intermediate = {
                    minVersion = "VersionTLS12";
                    sniStrict = true;

                    cipherSuites = [
                      "TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256"
                      "TLS_ECDHE_RSA_WITH_AES_128_GCM_SHA256"
                      "TLS_ECDHE_ECDSA_WITH_AES_256_GCM_SHA384"
                      "TLS_ECDHE_RSA_WITH_AES_256_GCM_SHA384"
                      "TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305"
                      "TLS_ECDHE_RSA_WITH_CHACHA20_POLY1305"
                    ];

                    curvePreferences = [
                      "X25519"
                      "CurveP256"
                      "CurveP384"
                    ];
                  };
                };

                http = {

                  middlewares = {

                    middlewares-basic-auth = {
                      basicAuth = {
                        usersFile = cfg.age.secrets.traefik_basic-auth_credentials.path;
                        realm = "Traefik 3 Basic Auth";
                        removeHeader = true;
                      };
                    };

                    middlewares-authelia = {
                      forwardAuth = {
                        address = myTraefikCfg.forwardAuthURL;
                        trustForwardHeader = true;
                        authResponseHeaders = [
                          "Remote-User"
                          "Remote-Groups"
                          "Remote-Name"
                          "Remote-Email"
                        ];
                      };
                    };

                    middlewares-compress = {
                      compress = { };
                    };

                    middlewares-contenttype = {
                      contentType = { };
                    };

                    middlewares-rate-limit = {
                      rateLimit = {
                        average = 100;
                        burst = 150;
                        period = "1s";
                      };
                    };

                    middlewares-secure-headers = {
                      headers = {
                        accessControlAllowMethods = [
                          "GET"
                          "OPTIONS"
                          "PUT"
                        ];

                        accessControlMaxAge = 100;
                        hostsProxyHeaders = [ "X-Forwarded-Host" ];
                        stsSeconds = 63072000;
                        stsIncludeSubdomains = true;
                        stsPreload = true;
                        customFrameOptionsValue = "SAMEORIGIN"; # https://developer.mozilla.org/en-US/docs/Web/HTTP/Headers/X-Frame-Options
                        contentTypeNosniff = true;
                        browserXssFilter = true;
                        referrerPolicy = "same-origin";
                        permissionsPolicy = "camera=(), microphone=(), geolocation=(), payment=(), usb=(), vr=()";

                        customResponseHeaders = {
                          X-Robots-Tag = "none,noarchive,nosnippet,notranslate,noimageindex,"; # disable search engines from indexing server
                          server = ""; # hide server info from visitors
                        };
                      };
                    };

                    chain-authelia = {
                      chain.middlewares = [
                        "middlewares-rate-limit"
                        "middlewares-authelia"
                        "middlewares-contenttype"
                        "middlewares-secure-headers"
                        "middlewares-compress"
                      ];
                    };

                    chain-basic-auth = {
                      chain.middlewares = [
                        "middlewares-rate-limit"
                        "middlewares-basic-auth"
                        "middlewares-contenttype"
                        "middlewares-secure-headers"
                        "middlewares-compress"
                      ];
                    };

                    chain-no-auth = {
                      chain.middlewares = [
                        "middlewares-rate-limit"
                        "middlewares-contenttype"
                        "middlewares-secure-headers"
                        "middlewares-compress"
                      ];
                    };

                  };
                };
              };

            };
          };

          environment.etc = generateRules myTraefikCfg.rules;
        })

        (lib.mkIf myTraefikCfg.enable {

          # environment.etc =
          #   generateDynFile "dashboard" {
          #     http.routers.traefik-rtr = {
          #       entrypoints = "websecure";
          #       rule = "Host(`${myTraefikCfg.domain}`) && (PathPrefix(`/traefik/api`) || PathPrefix(`/traefik/dashboard`))";
          #       service = "api@internal";
          #       middlewares = "chain-no-auth@file";
          #     };
          #   }
          #   // generateDynFile "metrics" {
          #     http.routers.metrics-rtr = {
          #       entrypoints = "websecure";
          #       rule = "Host(`${myTraefikCfg.domain}`) && PathPrefix(`/metrics`)";
          #       service = "prometheus@internal";
          #       middlewares = "chain-no-auth@file";
          #     };
          #   };
        })
      ];
    };
}
