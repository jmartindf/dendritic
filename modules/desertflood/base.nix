{ inputs, ... }:
let
  myTimezone = "America/Phoenix";
  myLocale = "en_US.UTF-8";
  pkiRootCert =
    pkgs:
    pkgs.fetchurl {
      url = "https://pki.desertflood.link/roots.pem";
      hash = "sha256-tgK+D2q/bJBZCDh+7Cf9ha2wSzIfh7n2HZi5Vif6g1k=";
      curlOpts = "--insecure";
    };
  stepConfig =
    pkgs:
    pkgs.writeTextFile {
      name = "step-defaults.json";
      text = builtins.toJSON {
        ca-url = "https://pki.desertflood.link";
        fingerprint = "be95020a50bc30002b6f5a2ea3cd827b169412235192adeb3296a827d0036e00";
        root = "${pkiRootCert pkgs}";
      };
    };
  step =
    pkgs:
    pkgs.writeShellApplication {
      name = "step";
      text = # bash
        ''
          ${pkgs.lib.getExe pkgs.step-cli} --config="${stepConfig pkgs}" "$@"
        '';
    };
  defaultPackages = pkgs: [
    pkgs.cacert
    pkgs.curl
    pkgs.ghostty.terminfo
    pkgs.gum
    (step pkgs)
    pkgs.vim
    pkgs.wget
  ];
in
{
  flake.modules.nixos.base =
    { pkgs, ... }:
    {
      time.timeZone = myTimezone;
      i18n.defaultLocale = myLocale;
      environment.systemPackages = defaultPackages pkgs;

      services.openssh = {
        enable = true;

        settings = {
          LogLevel = "INFO";
          PermitRootLogin = "prohibit-password";
          StrictModes = true;
        };

        extraConfig = ''
          # Authentication
          LoginGraceTime 2m
          MaxAuthTries 6
          MaxSessions 10

          # Host certificate verification
          HostCertificate /etc/ssh/ssh_host_ed25519_key-cert.pub

          # Environment
          AcceptEnv COLORTERM
        '';
      };

      services.tailscale.enable = true;

      security = {

        sudo = {
          wheelNeedsPassword = false;
          keepTerminfo = true;
        };

        pam = {
          sshAgentAuth.enable = true;

          services = {
            su.enable = true;
            su.sshAgentAuth = true;
            sudo.enable = true;
            sudo.sshAgentAuth = true;
            sudo-i.enable = true;
            sudo-i.sshAgentAuth = true;
          };

        };
      };

      security.pki.certificateFiles = [
        (pkiRootCert pkgs)
      ];

      nix = {

        registry.nixpkgs.to = {
          type = "path";
          path = inputs.nixpkgs;
        };
        nixPath = [ "nixpkgs=flake:nixpkgs" ];

        settings = {
          experimental-features = "nix-command flakes";

          substituters = [
            "https://cache.nixos.org"
            "https://nix-community.cachix.org"
            "https://nixpkgs-python.cachix.org"
            "https://attic.h.thosemartins.family/df-test"
          ];

          trusted-public-keys = [
            "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
            "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
            "nixpkgs-python.cachix.org-1:hxjI7pFxTyuTHn2NkvWCrAUcNZLNS3ZAvfYNuYifcEU="
            "df-test:nGcIjsIXVK/SZON7K4/IVCJPZ2PjNSRFyB2RBDHMPsU="
          ];
        };
      };

      systemd = {

        services = {
          renew-ssh-certificate = {
            name = "renew-ssh-certificate.service";
            description = "Weekly renewal for SSH host certificate";

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

            script = # bash
              ''
                ${pkgs.lib.getExe (step pkgs)} ssh renew "/etc/ssh/ssh_host_ed25519_key-cert.pub" "/etc/ssh/ssh_host_ed25519_key" --force 2> /dev/null
                exit 0
              '';

          };
        };

        timers = {

          renew-ssh-certificate = {
            name = "renew-ssh-certificate.timer";
            description = "Weekly renewal for SSH host certificate";
            wantedBy = [ "timers.target" ];

            timerConfig = {
              # Run 5 minutes after system / systemd start
              OnStartupSec = "5min";

              # Run weekly
              OnCalendar = "weekly";

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

  flake.modules.darwin.base =
    { pkgs, ... }:
    {
      time.timeZone = myTimezone;
      environment.systemPackages = defaultPackages pkgs;
    };
}
