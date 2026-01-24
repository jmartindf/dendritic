{ inputs, ... }:
{
  imports = [
    (inputs.flake-parts.flakeModules.modules or { })
    (inputs.flake-file.flakeModules.default or { })
    (inputs.flake-file.flakeModules.import-tree or { })
  ];

  config = {

    flake-file.outputs = # nix
      ''
        inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } (inputs.import-tree ./modules)
      '';

    flake-file.inputs = {
      flake-file.url = "github:vic/flake-file";

      flake-parts = {
        url = "github:hercules-ci/flake-parts";
        inputs.nixpkgs-lib.follows = "nixpkgs-lib";
      };

      import-tree.url = "github:vic/import-tree";
    };

  };
}
