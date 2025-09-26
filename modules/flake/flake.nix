{ inputs, lib, ... }:
{
  imports = [
    (inputs.dendrix.vic-vix.filter (lib.hasSuffix "mk-os.nix"))
    inputs.devshell.flakeModule
    inputs.flake-parts.flakeModules.modules
  ];

  config = {

    systems = import inputs.systems;

    perSystem =
      { config, pkgs, ... }:
      {
        # configure the flake's dev shell
        devshells.default = {

          packages = [
            pkgs.just
            pkgs.nix
            pkgs.nixos-rebuild-ng
            pkgs.nix-output-monitor
          ];

          commands = [
            {
              package = pkgs.nh;
              help = "Nix helper for nixpkgs development";
            }
            {
              package = pkgs.nix-tree;
              help = "Interactively browse dependency graphs of Nix derivations";
            }
            {
              package = pkgs.nvd;
              help = "Diff two nix toplevels and show which packages were upgraded";
            }
            {
              package = pkgs.nix-diff;
              help = "Explain why two Nix derivations differ";
            }
            {
              package = pkgs.nix-output-monitor;
              help = "Nix Output Monitor (a drop-in alternative for `nix` which shows a build graph)";
            }
          ];
        };

      };
  };
}
