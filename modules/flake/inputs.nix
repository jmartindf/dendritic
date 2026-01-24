{ inputs, ... }:
{

  config = {
    flake-file.inputs = {
      darwin = {
        url = "github:nix-darwin/nix-darwin/nix-darwin-25.11";
        inputs.nixpkgs.follows = "nixpkgs-darwin";
      };

      disko = {
        url = "github:nix-community/disko";
        inputs.nixpkgs.follows = "nixpkgs";
      };

      nixos-facter-modules.url = "github:numtide/nixos-facter-modules";
    };

  };
}
