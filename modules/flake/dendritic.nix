{ inputs, lib, ... }:
{

  imports = [
    (inputs.den.flakeModule or { })
    inputs.flake-aspects.flakeModule
    (inputs.dendrix.vic-vix.filter (lib.hasSuffix "mk-os.nix"))
  ];

  config = {

    flake-file.inputs = {
      den.url = "github:denful/den/v0.20.0";

      dendrix = {
        url = "github:vic/dendrix";
        inputs.import-tree.follows = "import-tree";
        inputs.nixpkgs-lib.follows = "nixpkgs-lib";
      };

      flake-aspects.url = "github:vic/flake-aspects";
    };

  };
}
