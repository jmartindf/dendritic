{ inputs, ... }:
{
  imports = [
    # inputs.git-hooks-nix.flakeModule
  ];

  config = {

    perSystem =
      {
        config,
        inputs',
        pkgs,
        self',
        system,
        ...
      }:
      {
        # pre-commit.settings.hooks.nixpkgs-fmt.enable = true;
        #
        # devshells.default = {
        #   packages = [ config.pre-commit.settings.enabledPackages ];
        #   startup.hook.text = "${config.pre-commit.shellHook}";
        # };
      };

    flake-file.inputs.git-hooks-nix = {
      url = "github:cachix/git-hooks.nix";

      inputs = {
        flake-compat.follows = "flake-compat";
        nixpkgs.follows = "nixpkgs";
      };
    };

  };
}
