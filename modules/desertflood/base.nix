{ inputs, ... }:
let
  myTimezone = "America/Phoenix";
  myLocale = "en_US.UTF-8";
  defaultPackages = pkgs: [
    pkgs._1password-cli
    pkgs.cacert
    pkgs.curl
    pkgs.direnv
    pkgs.ghostty.terminfo
    pkgs.git
    pkgs.gum
    pkgs.just
    pkgs.vim
    pkgs.wget
  ];
in
{
  flake.modules.nixos.base =
    { lib, pkgs, ... }:
    {
      time.timeZone = myTimezone;
      i18n.defaultLocale = myLocale;

      nixpkgs.config.allowUnfreePredicate =
        pkg:
        builtins.elem (lib.getName pkg) [
          "1password-cli"
        ];

      environment.systemPackages = defaultPackages pkgs;

      services = {

        openssh = {
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

            # Environment
            AcceptEnv COLORTERM
          '';
        };
      };

      security = {

        sudo = {
          wheelNeedsPassword = false;
          keepTerminfo = true;
          extraConfig = ''
            # "sudo scp" or "sudo rsync" should be able to use your SSH agent.
            Defaults:%sudo env_keep += "SSH_AGENT_PID SSH_AUTH_SOCK SSH_CONNECTION SSH_CLIENT SSH_TTY"

            # Ditto for GPG agent
            Defaults:%sudo env_keep += "GPG_AGENT_INFO"

            # Per-user preferences; root won't have sensible values for them.
            Defaults:%sudo env_keep += "EMAIL DEBEMAIL DEBFULLNAME"
            Defaults:%sudo env_keep += "GIT_AUTHOR_* GIT_COMMITTER_*"

            # This allows running arbitrary commands, but so does ALL, and it means
            # different sudoers have their choice of editor respected.
            Defaults:%sudo env_keep += "EDITOR"

            # Completely harmless preservation of color preferences.
            Defaults:%sudo env_keep += "GREP_COLOR COLORTERM"
          '';
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
    };

  flake.modules.darwin.base =
    { pkgs, ... }:
    {
      time.timeZone = myTimezone;
      environment.systemPackages = defaultPackages pkgs;
    };
}
