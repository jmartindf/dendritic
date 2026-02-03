{ den, ... }:
let
  shellLaunchFish =
    config: pkgs: # sh
    ''
      # Launch into fish, if it's not already running
      if [[ $- == *i* ]] # only for interactive shells
      then
        if [[ $(${pkgs.procps}/bin/ps -p $PPID -o ucomm= | tr -d '[:space:]') != "fish" && -z ''${BASH_EXECUTION_STRING} ]]
        then
          shopt -q login_shell && LOGIN_OPTION='--login' || LOGIN_OPTION=""
          exec ${config.programs.fish.package}/bin/fish $LOGIN_OPTION
        fi
      fi
    '';

  osContext =
    { OS, host }:
    {
      nixos =
        {
          config,
          pkgs,
          ...
        }:
        let
          nixosCfg = config;
        in
        {
          config = {
            environment =
              builtins.traceVerbose "configuring fish for NixOS (${host.name}) as part of df.cli._.fish"
                {
                  etc."bashrc.local".text = shellLaunchFish nixosCfg pkgs;
                };

            programs = {
              fish = {
                enable = true;
                generateCompletions = false; # Generating completions from man pages is slow and mostly unnecessary
              };
            };
          };
        };

      darwin =
        {
          config,
          pkgs,
          ...
        }:
        let
          darwinCfg = config;
        in
        {
          config = {
            environment = {
              etc."bashrc.local".text = shellLaunchFish darwinCfg pkgs;
            };

            programs = {
              fish = {
                enable = true;
              };
            };
          };
        };

    };

  homeContext =
    { user, ... }:
    {
      homeManager =
        {
          pkgs,
          lib,
          ...
        }:
        {
          config = {
            programs = builtins.traceVerbose "configuring fish for ${user.userName} as part of df.cli._.fish" {
              fish = {
                enable = true;
                generateCompletions = false; # Generating completions from man pages is slow and mostly unnecessary
              };
            };
          };
        };
    };
in
{
  df.cli.includes = [
    (den.lib.take.exactly osContext)
    homeContext
  ];
}
