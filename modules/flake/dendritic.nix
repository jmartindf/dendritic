{ inputs, lib, ... }:
{

  imports = [
    (inputs.den.flakeModule or { })
    inputs.flake-aspects.flakeModule
    (inputs.dendrix.vic-vix.filter (lib.hasSuffix "mk-os.nix"))
  ];

  config = {

    flake.modules = {

      nixos = {
        x86_64-linux = { };
        aarch64-linux = { };
        nixos = { };
      };

      darwin = {
        aarch64-darwin = { };
        darwin = { };
      };

    };

    flake-file.inputs = {
      den.url = "github:vic/den";

      dendrix = {
        url = "github:vic/dendrix";
        inputs.import-tree.follows = "import-tree";
        inputs.nixpkgs-lib.follows = "nixpkgs-lib";
      };

      flake-aspects.url = "github:vic/flake-aspects";
    };

  };
}
