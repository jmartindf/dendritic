_: {

  flake.modules.nixos.crowdsec =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {

      options = {
        desertflood.services.crowdsec.enable = lib.mkEnableOption "crowdsec scanning and mitigation";
      };

      config =
        let
          nixOScfg = config;
          api_at = "127.0.0.1:8888";
          firewallBouncerName = "FranceFirewallBouncer";
        in
        lib.mkIf nixOScfg.desertflood.services.crowdsec.enable {

          age.secrets =
            let
              ownership = {
                owner = "${nixOScfg.services.crowdsec.user}";
                group = "${nixOScfg.services.crowdsec.group}";
              };
            in
            {
              crowdsec-bouncer-api_key.rekeyFile = ./bouncer-api_key.age;
              crowdsec-enroll-key = {
                rekeyFile = ./enrollment_key.age;
              }
              // ownership;
              crowdsec-local-credentials = {
                rekeyFile = ./local_api_credentials.yaml.age;
                name = "local_api_credentials.yaml";
              }
              // ownership;
              crowdsec-central-credentials = {
                rekeyFile = ./central_api_credentials.yaml.age;
                name = "central_api_credentials.yaml";
              }
              // ownership;
            };

          services.crowdsec = {
            enable = true;
            autoUpdateService = true;

            settings = {

              general.api = {
                server.enable = true;
                server.listen_uri = api_at;
              };

              lapi.credentialsFile = nixOScfg.age.secrets.crowdsec-local-credentials.path;
              capi.credentialsFile = nixOScfg.age.secrets.crowdsec-central-credentials.path;

              console = {
                tokenFile = nixOScfg.age.secrets.crowdsec-enroll-key.path;

                configuration = {
                  share_manual_decisions = true;
                  share_tainted = true;
                  share_custom = true;
                  console_management = false;
                  share_context = true;
                };
              };
            };

            hub = {
              collections = [
                "crowdsecurity/linux"
                "crowdsecurity/base-http-scenarios"
                "crowdsecurity/http-cve"
                "crowdsecurity/caddy"
                "LePresidente/grafana"
                "Jgigantino31/ntfy"
                "crowdsecurity/traefik"
              ];
            };

            localConfig = {

              acquisitions = [
                {
                  source = "journalctl";
                  journalctl_filter = [
                    "_SYSTEMD_UNIT=sshd.service"
                    "_SYSTEMD_UNIT=traefik.service"
                    "_SYSTEMD_UNIT=caddy.service"
                    "_SYSTEMD_UNIT=forgejo.service"
                    "_SYSTEMD_UNIT=grafana.service"
                    "_SYSTEMD_UNIT=ntfy-sh.service"
                  ];
                  labels.type = "syslog";
                }
              ];

              parsers.s02Enrich = [
                {
                  name = "jmartindf/http-allow-nix-cache";
                  description = "Whitelist HTTP requests that are checking a Nix cache for specific NARs";

                  whitelist = {
                    reason = "NAR checks for Nix cache";

                    expression = [
                      ''evt.Parsed.request matches "^/[\\w\\d-]+/[\\w\\d-]+\\.narinfo$" && evt.Parsed.verb == "GET"''
                    ];
                  };
                }
                {
                  name = "jmartindf/http-allow-taskchampion-sync";
                  description = "Whitelist askchampion-sync-server API calls that generate 404 responses";

                  whitelist = {
                    reason = "valid taskchampion-sync-server usage";

                    expression = [
                      ''evt.Parsed.request matches "^/v1/client/get-child-version/[\\w\\d-]+$" && evt.Parsed.verb == "GET"''
                    ];
                  };
                }
              ];
            };

          };

          services.crowdsec-firewall-bouncer = {
            enable = true;

            settings = {
              api_url = "http://${api_at}";
              ipset_type = "nethash";
              deny_action = "DROP";
            };

            secrets.apiKeyPath = nixOScfg.age.secrets.crowdsec-bouncer-api_key.path;
            registerBouncer = {
              enable = false;
              bouncerName = firewallBouncerName;
            };
          };

          systemd.services.crowdsec.serviceConfig = {

            LoadCredential = [ "api_key:${nixOScfg.age.secrets.crowdsec-bouncer-api_key.path}" ];

            ExecStartPre =
              let
                script-bouncer =
                  pkgs.writeScriptBin "register-bouncer" # bash
                    ''
                      #!${pkgs.runtimeShell}
                      set -eu
                      set -o pipefail
                      cscli=/run/current-system/sw/bin/cscli

                      if ! $cscli bouncers list | ${pkgs.gnugrep}/bin/grep -q "${firewallBouncerName}"; then
                        $cscli bouncers add "${firewallBouncerName}" --key $(systemd-creds cat api_key)
                      fi
                    '';

              in
              [
                "${script-bouncer}/bin/register-bouncer"
              ];
          };

        };

    };

}
