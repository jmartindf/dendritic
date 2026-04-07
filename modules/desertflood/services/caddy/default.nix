{ config, lib, ... }:
let
  flakeCfg = config;
in
{
  flake.modules.nixos.services =
    { config, pkgs, ... }:
    let
      cfg = config;
      caddyCfg = cfg.desertflood.services.caddy;
      caddyUser = caddyCfg.user;
      caddyGroup = caddyCfg.group;

      leCfg = caddyCfg.letsencrypt;

      caddyWithPlugins = pkgs.local.caddy.withPlugins {
        plugins = [
          "github.com/abiosoft/caddy-json-schema@v0.0.0-20220621031927-c4d6e132f3af"
          "github.com/caddy-dns/acmedns@v0.6.0"
          "github.com/darkweak/souin/plugins/caddy@v1.7.8"
          "github.com/darkweak/storages/nuts/caddy@v0.0.16"
          "github.com/darkweak/storages/simplefs/caddy@v0.0.16"
          "github.com/greenpau/caddy-security@v1.1.31"
          "github.com/lucaslorentz/caddy-docker-proxy/v2@v2.10.0"
          "git.desertflood.com/jmartindf/caddy-fs-s3@v0.0.0-20251102022705-124d7ea62120"
          "git.desertflood.com/jmartindf/caddy-s3-proxy@v0.0.0-20251101025924-56966419076b"
        ];
        hash = "sha256-3R+f85RS9iBkdj4p5qL1jXzlDn5hJkf4i339LcXyVt4=";
      };

      configFile =
        let
          Caddyfile =
            pkgs.writeTextDir "Caddyfile" # caddy
              ''
                {
                  ${caddyCfg.settings.global}
                }

                ${caddyCfg.settings.snippets}

                ${caddyCfg.settings.site-blocks}
              '';

          Caddyfile-formatted = pkgs.runCommand "Caddyfile-formatted" { } ''
            mkdir -p $out
            cp --no-preserve=mode ${Caddyfile}/Caddyfile $out/Caddyfile
            ${caddyWithPlugins}/bin/caddy fmt --overwrite $out/Caddyfile
          '';
        in
        "${
          if pkgs.stdenv.buildPlatform == pkgs.stdenv.hostPlatform then Caddyfile-formatted else Caddyfile
        }/Caddyfile";

    in
    {
      imports = [ ];

      options.desertflood = {

        services.caddy = {
          enable = lib.mkEnableOption "customized Caddy application server";

          letsencrypt = {
            enable = lib.mkEnableOption "using LetsEncrypt for SSL certificates";

            production = lib.mkOption {
              type = lib.types.bool;
              default = false;
              description = "Use the LetsEncrypt production server instead of staging";
            };

            acme-dns = lib.mkEnableOption "Use the acme-dns DNS01 challenge and default accounts for challenges";

            tailscaleCerts = lib.mkEnableOption "Get certificates from Tailscale, for secure HTTP.";
          };

          settings = {

            disableSSL = lib.mkEnableOption "Disable automatic certificate management entirely";

            debug = lib.mkEnableOption "debug logging";

            global = lib.mkOption {
              type = lib.types.lines;
              default = # caddy
                ''
                  admin unix//run/caddy/caddy-admin.sock
                '';
              example = # caddy
                ''
                  local_certs
                '';
              description = "Global configuration options for Caddy";
            };

            snippets = lib.mkOption {
              type = lib.types.lines;
              default = "";
              description = "Snippets and named routes, for the Caddyfile";
            };

            site-blocks = lib.mkOption {
              type = lib.types.lines;
              default = "";
              description = "The rest of the Caddyfile configuration";
            };

          };

          user = lib.mkOption {
            type = lib.types.str;
            default = "caddy";
            description = "The user to run the caddy service under";
          };

          group = lib.mkOption {
            type = lib.types.str;
            default = "caddy";
            description = "The group to run the caddy service under";
          };
        };

      };

      config = lib.mkMerge [
        {
          desertflood.services.caddy = {

            letsencrypt = {
              enable = lib.mkDefault false;
              acme-dns = lib.mkDefault false;
              production = lib.mkDefault false;
            };

            settings = {

              global = # caddy
              ''
                admin unix//run/caddy/caddy-admin.sock

                ${lib.optionalString caddyCfg.settings.debug "debug"}

                log default {
                  output stderr
                  level ${if caddyCfg.settings.debug then "DEBUG" else "WARN"}
                  ${if caddyCfg.settings.debug then "" else "include http.log.access admin.api"}
                }

                servers {
                  trusted_proxies static 127.0.0.1/8 fd00::/8 ::1
                  client_ip_headers X-Forwarded-For X-Real-IP
                  ${lib.optionalString caddyCfg.settings.debug "trace"}
                }

              ''
              + (
                if leCfg.enable then # caddy
                  ''
                    email ${flakeCfg.desertflood.defaultUser.emails.desertflood.email}
                    acme_ca ${
                      if leCfg.production then
                        "https://acme-v02.api.letsencrypt.org/directory"
                      else
                        "https://acme-staging-v02.api.letsencrypt.org/directory"
                    }

                  ''
                else if caddyCfg.settings.disableSSL then
                  "auto_https off"
                else
                  "local_certs"
              );

              snippets = "";

              site-blocks = "";
            };

          };
        }
        (lib.mkIf caddyCfg.enable {

          age.secrets.acme-dns-caddy-json = {
            rekeyFile = ../acme-dns.json.age;
            owner = caddyUser;
            group = caddyGroup;
          };

          desertflood.services.caddy.settings = {

            snippets =
              lib.optionalString (leCfg.enable && leCfg.acme-dns) # caddy
                ''
                  (challenge_dns_acme-dns) {
                    tls {
                      dns acmedns ${cfg.age.secrets.acme-dns-caddy-json.path}
                      propagation_delay 60s
                      resolvers 1.1.1.1
                    }
                  }
                '';
          };

          # https://github.com/quic-go/quic-go/wiki/UDP-Buffer-Sizes
          boot.kernel.sysctl."net.core.rmem_max" = lib.mkDefault 2500000;
          boot.kernel.sysctl."net.core.wmem_max" = lib.mkDefault 2500000;

          networking.firewall.allowedTCPPorts = [
            80
            443
          ];

          environment = {

            systemPackages = [ caddyWithPlugins ];
            etc."caddy/Caddyfile".source = configFile;

          };

          users.users.${caddyUser} = {
            createHome = true;
            description = "Caddy web server";
            group = caddyGroup;
            home = "/var/lib/caddy";
            isSystemUser = true;
            shell = null;
            uid = cfg.ids.uids.caddy;
          };

          users.groups.${caddyGroup} = {
            gid = cfg.ids.gids.caddy;
          };

          services = {
            tailscale.permitCertUid = lib.mkIf leCfg.tailscaleCerts caddyUser;
          };

          systemd.services.caddy = {

            description = "Caddy";
            documentation = [ "https://caddyserver.com/docs/" ];

            wantedBy = [ "multi-user.target" ];

            after = [
              "network.target"
            ];
            requires = [ "network.target" ];

            startLimitIntervalSec = 14400;
            startLimitBurst = 10;

            reloadTriggers = [ configFile ];

            serviceConfig = {
              User = caddyUser;
              Group = caddyGroup;
              Type = "notify";

              ReadWritePaths = "/var/lib/caddy";
              StateDirectory = "caddy";
              LogsDirectory = "caddy";
              RuntimeDirectory = "caddy";
              ConfigurationDirectory = "caddy";
              Environment = [ "HOME=/var/lib/caddy" ];

              ExecStart = lib.concatStringsSep " " [
                "${caddyWithPlugins}/bin/caddy"
                "run"
                (lib.optionalString caddyCfg.settings.debug "--environ") # log environment at startup
                "--config"
                "/etc/caddy/Caddyfile"
              ];

              ExecReload = lib.concatStringsSep " " [
                "${caddyWithPlugins}/bin/caddy"
                "reload"
                "--config"
                "/etc/caddy/Caddyfile"
                "--force"
              ];

              Restart = "on-failure";
              RestartPreventExitStatus = 1;
              RestartSec = "5s";

              TimeoutStopSec = "5s";

              LimitNOFILE = 1048576;

              PrivateTmp = true;

              ProtectSystem = "full";
              ProtectHome = true;

              AmbientCapabilities = [
                "CAP_NET_ADMIN"
                "CAP_NET_BIND_SERVICE"
              ];
            };

          };

        })
      ];
    };
}
