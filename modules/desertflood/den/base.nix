{
  df,
  den,
  inputs,
  ...
}:
let
  myTimezone = "America/Phoenix";
  myLocale = "en_US.UTF-8";

  defaultPackages = pkgs: [
    pkgs._1password-cli
    pkgs.bat # A cat(1) clone with syntax highlighting and Git integration
    pkgs.bat-extras.batgrep
    pkgs.bat-extras.batman
    pkgs.bat-extras.batwatch
    pkgs.cacert
    pkgs.curl
    pkgs.direnv
    pkgs.eza
    pkgs.fd # simple, fast and user-friendly alternative to find
    pkgs.ghostty.terminfo
    pkgs.git
    pkgs.gum
    pkgs.just # Handy way to save and run project-specific commands
    pkgs.local.fqdn
    pkgs.nixos-rebuild-ng
    pkgs.ripgrep # the usability of The Silver Searcher with the raw speed of grep
    pkgs.rsync
    pkgs.sd # Intuitive find & replace CLI (sed alternative)
    pkgs.vim
    pkgs.wget
  ];

  batSettingsForHM = {
    italic-text = "always";
    map-syntax = [ ".ignore:Git Ignore" ];
    pager = "less --raw-control-chars --quit-if-one-screen --mouse";
  };

  batSettingsForNixOS = {
    italic-text = "always";
    map-syntax = [ "'.ignore:Git Ignore'" ];
    pager = "'less --raw-control-chars --quit-if-one-screen --mouse'";
  };

  osContext =
    { OS, host }:
    {
      nixos =
        {
          config,
          lib,
          pkgs,
          ...
        }:
        let
          dfCfg = config.desertflood;
        in
        {
          # builtins.break, to inspect `OS` and `host` in the REPL
          imports = [
            inputs.self.modules.nixos.nixos # While migrating to Den from plain Dendritic
            inputs.self.modules.nixos.agenix
          ];

          config = {

            environment = {

              shellAliases = {
                cat = "bat";
              };

              systemPackages = defaultPackages pkgs;
              etc.fqdn.text = "${config.desertflood.hostInfo.fqdn}";

              variables = {
                PAGER = "bat";
                MANPAGER = "${pkgs.coreutils-full}/bin/env BATMAN_IS_BEING_MANPAGER=yes ${pkgs.bashNonInteractive}/bin/bash ${pkgs.bat-extras.batman}/bin/batman";
              };

            };

            programs = {
              bat = {
                enable = true;

                settings = batSettingsForNixOS;
              };
            };

            # Manage DNS through systemd-resolved
            networking.resolvconf.enable = false;

            services = {
              # Manage DNS through systemd-resolved
              resolved = {
                enable = true;

                domains = [
                  "home.thosemartins.family"
                  "desertflood.com"
                  "df.fyi"
                  dfCfg.networking.tailscaleDomain
                ];

                fallbackDns = [
                  "1.1.1.1"
                  "1.0.0.1"
                  "2606:4700:4700::1111"
                  "2606:4700:4700::1001"
                ];
              };

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
                  "https://attic.desertflood.com/df-test"
                ];

                trusted-public-keys = [
                  "cache.nixos.org-1:6NCHdD59X431o0gWypbMrAURkbJ16ZPMQFGspcDShjY="
                  "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
                  "nixpkgs-python.cachix.org-1:hxjI7pFxTyuTHn2NkvWCrAUcNZLNS3ZAvfYNuYifcEU="
                  "df-test:nGcIjsIXVK/SZON7K4/IVCJPZ2PjNSRFyB2RBDHMPsU="
                ];

                always-allow-substitutes = true;
                auto-optimise-store = true;
              };

              # Run a weekly garbage collection
              # Clean up any profiles older than 21 days
              gc = {
                dates = "weekly";
                automatic = true;
                persistent = true;
                randomizedDelaySec = "45min";
                options = "--delete-older-than 21d";
              };
            };

            networking = {
            };
          };
        };

      darwin =
        {
          config,
          lib,
          pkgs,
          ...
        }:
        let
          darwinCfg = config;
        in
        {
          imports = [
            inputs.self.modules.darwin.darwin # While migrating to Den from plain Dendritic
          ];

          config = {
            environment = {
              shellAliases = {
                cat = "bat";
              };

              systemPackages = defaultPackages pkgs;

              variables = {
                PAGER = "bat";
                MANPAGER = "${pkgs.coreutils-full}/bin/env BATMAN_IS_BEING_MANPAGER=yes ${pkgs.bashNonInteractive}/bin/bash ${pkgs.bat-extras.batman}/bin/batman";
              };
            };
          };
        };
    };

  homeContext =
    { user, host, ... }:
    {
      homeManager =
        { pkgs, lib, ... }:
        {
          config = {
            # https://github.com/BurntSushi/ripgrep/blob/master/GUIDE.md#configuration-file
            programs =
              builtins.traceVerbose "configuring ripgrep and bat as part of df.base for user ${user.userName}"
                {
                  # https://github.com/sharkdp/bat
                  # https://nix-community.github.io/home-manager/options.xhtml#opt-programs.bat.enable
                  bat =
                    if lib.hasSuffix "darwin" host.system then
                      {
                        enable = true;

                        # config = lib.mkIf pkgs.stdenv.isDarwin batSettings;
                        config = batSettingsForHM;
                      }
                    else
                      { };

                  ripgrep = {
                    enable = true;

                    arguments = [
                      "--max-columns=150"
                      "--max-columns-preview"
                      "--hidden"
                      "--glob=!.git/*"
                      "--colors=line:none"
                      "--colors=line:style:bold"
                      "--smart-case"
                    ];
                  };
                };
          };
        };
    };

  description = "Common to all machines and homes";
in
{
  df.base = den.lib.parametric {
    inherit description;
    includes = [
      (den.lib.take.exactly osContext)
      homeContext
      df.cli
    ];
  };
}
