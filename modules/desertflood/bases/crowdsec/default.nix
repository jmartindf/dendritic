{ inputs, ... }:
{

  flake.modules.nixos.crowdsec =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    {

      imports = [
        inputs.crowdsec.nixosModules.crowdsec
        inputs.crowdsec.nixosModules.crowdsec-firewall-bouncer
      ];

      options = {
        desertflood.services.crowdsec.enable = lib.mkEnableOption "crowdsec scanning and mitigation";
      };

      config =
        let
          nixOScfg = config;
          api_at = "127.0.0.1:8888";
        in
        lib.mkIf nixOScfg.desertflood.services.crowdsec.enable {

          age.secrets.crowdsec-enroll-key.rekeyFile = ./enrollment_key.age;
          age.secrets.crowdsec-bouncer-api_key.rekeyFile = ./bouncer-api_key.age;

          nixpkgs.overlays = [ inputs.crowdsec.overlays.default ];

          services.crowdsec =
            let
              yaml = (pkgs.formats.yaml { }).generate;
              acquisitions_file = yaml "acquisitions.yaml" {
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
              };
            in
            {
              enable = true;
              enrollKeyFile = nixOScfg.age.secrets.crowdsec-enroll-key.path;
              allowLocalJournalAccess = true;
              settings = {
                api.server.listen_uri = api_at;
                crowdsec_service.acquisition_path = acquisitions_file;
              };
            };

          services.crowdsec-firewall-bouncer = {
            enable = true;
            settings = {
              api_url = "http://${api_at}";
              api_key = "@API_KEY@";
            };
          };

          systemd.services.crowdsec-firewall-bouncer.serviceConfig =
            let
              format = pkgs.formats.yaml { };
              configFile = format.generate "crowdsec.yaml" nixOScfg.services.crowdsec-firewall-bouncer.settings;
              configFileName = "crowdsec-bouncer.yaml";

              hydrate =
                pkgs.writeScriptBin "hydrate-bouncer-config" # bash
                  ''
                    #!${pkgs.runtimeShell}
                    set -eu
                    set -o pipefail

                    install -m 0600 ${configFile} $RUNTIME_DIRECTORY/${configFileName}

                    ${pkgs.replace-secret}/bin/replace-secret \
                      '@API_KEY@' \
                      $CREDENTIALS_DIRECTORY/api_key \
                      $RUNTIME_DIRECTORY/${configFileName}
                  '';

              check =
                pkgs.writeScriptBin "bouncer-config-check" # bash
                  ''
                    #!${pkgs.runtimeShell}
                    set -eu
                    set -o pipefail

                    ${pkgs.crowdsec-firewall-bouncer}/bin/cs-firewall-bouncer \
                      -t -c $RUNTIME_DIRECTORY/${configFileName}
                  '';

              run =
                pkgs.writeScriptBin "bouncer-run" # bash
                  ''
                    #!${pkgs.runtimeShell}
                    set -eu
                    set -o pipefail

                    exec ${pkgs.crowdsec-firewall-bouncer}/bin/cs-firewall-bouncer \
                      -c $RUNTIME_DIRECTORY/crowdsec-bouncer.yaml
                  '';
            in
            {
              RuntimeDirectory = "crowdsec-firewall-bouncer";

              ExecStartPre = lib.mkForce [
                "${hydrate}/bin/hydrate-bouncer-config"
                "${check}/bin/bouncer-config-check"
              ];

              ExecStart = lib.mkForce "${run}/bin/bouncer-run";

              LoadCredential = [ "api_key:${nixOScfg.age.secrets.crowdsec-bouncer-api_key.path}" ];
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

                      if ! cscli bouncers list | grep -q "FranceFirewallBouncer"; then
                        cscli bouncers add "FranceFirewallBouncer" --key $(systemd-creds cat api_key)
                      fi
                    '';

                script-scenarios =
                  pkgs.writeScriptBin "install-scenarios" # bash
                    ''
                      #!${pkgs.runtimeShell}
                      set -eu
                      set -o pipefail

                      if ! cscli collections list | grep -q "crowdsecurity/linux"; then
                        cscli collections install crowdsecurity/linux
                      fi

                      if ! cscli collections list | grep -q "crowdsecurity/base-http-scenarios"; then
                        cscli collections install crowdsecurity/base-http-scenarios
                      fi

                      if ! cscli collections list | grep -q "crowdsecurity/http-cve"; then
                        cscli collections install crowdsecurity/http-cve
                      fi

                      if ! cscli collections list | grep -q "crowdsecurity/caddy"; then
                        cscli collections install crowdsecurity/caddy
                      fi

                      if ! cscli collections list | grep -q "LePresidente/grafana"; then
                        cscli collections install LePresidente/grafana
                      fi

                      if ! cscli collections list | grep -q "Jgigantino31/ntfy"; then
                        cscli collections install Jgigantino31/ntfy
                      fi

                      if ! cscli collections list | grep -q "crowdsecurity/traefik"; then
                        cscli collections install crowdsecurity/traefik
                      fi
                    '';
              in
              [
                "${script-bouncer}/bin/register-bouncer"
                "${script-scenarios}/bin/install-scenarios"
              ];
          };

        };

    };

}
