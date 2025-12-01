{ inputs, ... }:
let
  overlay = final: prev: {
    local = inputs.self.packages.${prev.stdenv.hostPlatform.system};
  };
in
{
  config = {
    perSystem =
      { system, config, ... }:
      {
        _module.args.pkgs = import inputs.nixpkgs {
          inherit system;
          overlays = [
            (final: prev: {
              local = config.packages;
            })
          ];
        };
      };

    flake.modules.nixos.nixos = {
      nixpkgs.overlays = [
        overlay
      ];
    };
  };
}
