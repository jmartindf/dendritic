{ df, ... }:
{
  df.cli = {
    description = "Everything related to the command line and TUIs";

    includes = [
      df.cli._.coreutils
      df.cli._.fish
    ];

    nixos = { };
    darwin = { };
    homeManager = { };

    _.coreutils =
      let
        batSettings = {
          italic-text = "always";
          map-syntax = [ "'.ignore:Git Ignore'" ];
          pager = "'less --raw-control-chars --quit-if-one-screen --mouse'";
        };
      in
      {
        description = "modern utilities such as eza, fd, bat, sd, etc.";

        nixos =
          { pkgs, ... }:
          {
            config = {
              environment = {
                shellAliases = {
                  cat = "bat";
                };

                systemPackages = builtins.traceVerbose "coreutils.nixos active" [
                  pkgs.bat # A cat(1) clone with syntax highlighting and Git integration
                  pkgs.bat-extras.batman
                  pkgs.bat-extras.batgrep
                  pkgs.bat-extras.batwatch
                  pkgs.coreutils-full
                  pkgs.dust # du + rust = dust. Like du but more intuitive
                  pkgs.fd # simple, fast and user-friendly alternative to find
                  pkgs.findutils
                  pkgs.gdu # TUI disk usage analyzer
                  pkgs.glow # Render markdown on the CLI, with pizzazz!
                  pkgs.gnused
                  pkgs.just # Handy way to save and run project-specific commands
                  pkgs.less # More advanced file pager than 'more'
                  pkgs.ntfy-sh # Push notifications made easy
                  pkgs.ripgrep # the usability of The Silver Searcher with the raw speed of grep
                  pkgs.sd # Intuitive find & replace CLI (sed alternative)
                ];

                variables = {
                  PAGER = "bat";
                  MANPAGER = "${pkgs.coreutils-full}/bin/env BATMAN_IS_BEING_MANPAGER=yes ${pkgs.bashNonInteractive}/bin/bash ${pkgs.bat-extras.batman}/bin/batman";
                };
              };

              programs = {
                bat = {
                  enable = true;

                  settings = batSettings;
                };
              };
            };
          };

        darwin =
          { pkgs, ... }:
          {
            config.environment = {
              shellAliases = {
                cat = "bat";
              };

              systemPackages = builtins.traceVerbose "coreutils.darwin active" [
                pkgs.bat # A cat(1) clone with syntax highlighting and Git integration
                pkgs.bat-extras.batman
                pkgs.bat-extras.batgrep
                pkgs.bat-extras.batwatch
                pkgs.coreutils-full
                pkgs.dust # du + rust = dust. Like du but more intuitive
                pkgs.fd # simple, fast and user-friendly alternative to find
                pkgs.findutils
                pkgs.gdu # TUI disk usage analyzer
                pkgs.glow # Render markdown on the CLI, with pizzazz!
                pkgs.gnused
                pkgs.just # Handy way to save and run project-specific commands
                pkgs.less # More advanced file pager than 'more'
                pkgs.ntfy-sh # Push notifications made easy
                pkgs.ripgrep # the usability of The Silver Searcher with the raw speed of grep
                pkgs.sd # Intuitive find & replace CLI (sed alternative)
              ];

              variables = {
                PAGER = "bat";
                MANPAGER = "${pkgs.coreutils-full}/bin/env BATMAN_IS_BEING_MANPAGER=yes ${pkgs.bashNonInteractive}/bin/bash ${pkgs.bat-extras.batman}/bin/batman";
              };
            };
          };

        homeManager =
          {
            pkgs,
            lib,
            ...
          }:
          {
            config = {
              programs = {

                # https://github.com/sharkdp/bat
                # https://nix-community.github.io/home-manager/options.xhtml#opt-programs.bat.enable
                bat = {
                  enable = true;

                  config = lib.mkIf pkgs.stdenv.isDarwin batSettings;
                };

                # https://github.com/BurntSushi/ripgrep/blob/master/GUIDE.md#configuration-file
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
  };
}
