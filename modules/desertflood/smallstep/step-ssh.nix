{ config, ... }:
let
  flakeCfg = config;
in
{
  flake.modules.nixos.step-ssh =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      nixOScfg = config;
    in
    {

      options = {

        desertflood.services.step-ssh = {

          principals = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            default = [ ];
            description = "Principal (host) names to include on the certificate";
          };

        };

      };

      config = {

        desertflood.services.step-ssh.principals = [
          nixOScfg.networking.hostName
          nixOScfg.networking.fqdn
          "${nixOScfg.networking.hostName}.${nixOScfg.desertflood.networking.tailscaleDomain}"
        ];

        age.secrets.provisioner-password.rekeyFile = ./provisioner-password.age;

        services = {

          openssh = {
            extraConfig = ''
              # Host certificate verification
              HostCertificate /etc/ssh/ssh_host_ed25519_key-cert.pub
              HostCertificate /etc/ssh/ssh_host_rsa_key-cert.pub
            '';
          };

        };

        systemd = {

          services =
            let
              rsaKey = "/etc/ssh/ssh_host_rsa_key";
              ed25519Key = "/etc/ssh/ssh_host_ed25519_key";

              principalString = lib.concatStringsSep " " (
                lib.map (host: "--principal '${host}'") nixOScfg.desertflood.services.step-ssh.principals
              );

              serviceTweaks = {

                enableStrictShellChecks = true;
                environment = {
                  STEPPATH = "/etc/step-ca";
                };
                path = [
                  pkgs.step-cli
                  pkgs.coreutils
                ];
                preStart = # bash
                  ''
                    function sign {
                      step ssh certificate \
                        --sign \
                        --provisioner '${flakeCfg.desertflood.step-ca.provisioner}' \
                        --provisioner-password-file="${config.age.secrets.provisioner-password.path}" \
                        --host --host-id machine ${principalString} \
                        "$(cat /etc/fqdn)" \
                        "$1"
                    }

                    if [[ ${ed25519Key}-cert.pub -ot ${ed25519Key} ]];
                    then
                      sign "${ed25519Key}.pub"
                    fi
                    if [[ ${rsaKey}-cert.pub -ot ${rsaKey} ]];
                    then
                      sign "${rsaKey}.pub"
                    fi
                  '';
              };
            in
            {

              "sshd@" = serviceTweaks;
              "sshd" = serviceTweaks;

              # inspired by https://github.com/vulpi/viperML-dotfiles/blob/0e0dacf03489596359d97fd8292da4921f902f29/hosts/gen6/configuration.nix
              # and
              # https://github.com/vulpi/viperML-dotfiles/blob/0e0dacf03489596359d97fd8292da4921f902f29/bin/renew_cert.sh
              renew-ssh-certificate = {
                name = "renew-ssh-certificate.service";
                description = "Daily renewal check for SSH host certificate, with step-ca and SSHPOP";

                wants = [
                  "network.target"
                  "network-online.target"
                ];

                after = [
                  "network.target"
                  "network-online.target"
                ];

                serviceConfig = {
                  Type = "oneshot";
                  User = "root";
                };

                enableStrictShellChecks = true;
                environment = {
                  STEPPATH = "/etc/step-ca";
                };
                path = [ pkgs.step-cli ];
                script = # bash
                  ''
                    function renewal_check {
                      step ssh inspect "$1-cert.pub"

                      set +o errexit
                      step ssh needs-renewal "$1-cert.pub" \
                        --expires-in="50%" &>/dev/null
                      status=$?
                      set -o errexit

                      if [ $status -eq 1 ]; then
                        echo "$1-cert.pub does not need renewal"
                      elif [ $status -eq 0 ]; then
                        echo "Renewing $1-cert.pub"
                        step ssh renew --force \
                          "$1-cert.pub" \
                          "$1"
                      else
                        echo "Unknown error"
                        echo ""
                        return 1
                      fi
                      echo ""
                    }

                    if [[ -f ${rsaKey}-cert.pub ]];
                    then
                      renewal_check "${rsaKey}"
                    fi

                    if [[ -f ${ed25519Key}-cert.pub ]];
                    then
                      renewal_check "${ed25519Key}"
                    fi

                    exit 0
                  '';
              };
            };

          timers.renew-ssh-certificate = {
            name = "renew-ssh-certificate.timer";
            description = "Daily renewal check for SSH host certificate, with step-ca and SSHPOP";
            wantedBy = [ "timers.target" ];

            timerConfig = {
              # Run 5 minutes after system / systemd start
              OnStartupSec = "5min";

              # Run daily
              OnCalendar = "daily";

              # Delay the timer by a randomly selected, evenly distributed amount of time between
              # 0 seconds and 30 minutes
              RandomizedDelaySec = 1800;

              # Coalesce CPU wakeups
              AccuracySec = "1h";

              # store the time when the service unit was last triggered
              # When the timer is activated, trigger the service unit immediately
              # if it would have been triggered at least while inactive
              Persistent = true;
            };
          };
        };

      };

    };

}
