_: {
  df.cli._.coreutils =
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
    in
    {
      nixos =
        { pkgs, ... }:
        {
          config = {
            environment = builtins.trace "df.cli._.coreutils extra for eza active" {
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

              systemPackages = builtins.trace "coreutils.darwin active" [
                pkgs.eza # modern, maintained replacement for ls
              ];
            };

            programs.fish.interactiveShellInit = ezaFishFunctions;
          };
        };

      homeManager = _: {
        config = {
          programs = {
            fish = {

            };
          };
        };
      };
    };
}
