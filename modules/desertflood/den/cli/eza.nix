{ den, ... }:
let
  ezaAliases = {
    ls = "eza";
    ll = "eza -l";
    la = "eza -a";
    lt = "eza --tree";
    lla = "eza -la";
  };

  ezaFishFunctions = # fish
    ''
      set -g __eza_global_opts --group-directories-first --header --oneline --long --git --icons

      function ez --wraps eza --description "Run eza with my preferred default options"
          eza $__eza_global_opts --time-style=relative --no-permissions --dereference --smart-group $argv
      end

      function ezaa --wraps eza --description "Run eza with my preferred default options, showing hidden files"
          eza $__eza_global_opts --time-style=relative --no-permissions --dereference --smart-group --all $argv
      end

      function ezl --wraps eza --description "show permissions and group"
          eza $__eza_global_opts --time-style=relative $argv
      end

      function ezla --wraps eza --description "show permissions and group, include hidden files"
          ezl --all $argv
      end

      function ezll --wraps eza --description "show octal permissions, group, exact created time"
          eza $__eza_global_opts --time-style=long-iso --octal-permissions $argv
      end

      function ezlla --wraps eza --description "show octal permissions, group, exact created time, including hidden files"
          ezll --all $argv
      end

      function ezt --wraps eza --description "Eza show a tree"
          ez --tree $argv
      end

      function ezta --wraps eza --description "Eza show a tree, including hidden files"
          ezt --all $argv
      end

      function ls --wraps ez --description 'Reminder to use eza, not ls'
          echo "(or use `ez` directly)"
          ez $argv
      end
    '';

  osContext =
    { host }:
    {
      nixos =
        { pkgs, ... }:
        {
          config = {
            environment =
              builtins.traceVerbose
                "${host.class} system configuring eza for ${host.name} as part of df.cli._.eza"
                {
                  shellAliases = ezaAliases;
                  systemPackages = [
                    pkgs.eza # modern, maintained replacement for ls
                  ];
                };

            programs.fish.interactiveShellInit = ezaFishFunctions;
          };
        };

      darwin =
        { pkgs, ... }:
        {
          config = {

            environment = {
              shellAliases = ezaAliases;

              systemPackages = builtins.traceVerbose "coreutils.darwin active" [
                pkgs.eza # modern, maintained replacement for ls
              ];
            };

            programs.fish.interactiveShellInit = ezaFishFunctions;
          };
        };

    };

  homeContext =
    { user, ... }:
    {
      homeManager = _: {
        config = {
          programs = {
            fish = {

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
