{ inputs, lib, ... }:
{

  imports = [
    (inputs.den.flakeModule or { })
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
      den.url = "github:vic/den/v0.16.0";

      dendrix = {
        url = "github:vic/dendrix";
        inputs.import-tree.follows = "import-tree";
        inputs.nixpkgs-lib.follows = "nixpkgs-lib";
      };
    };

  };
}
