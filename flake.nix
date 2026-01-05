{
  description = "Various systems for Joe Martin / Desertflood";

  outputs = inputs: inputs.flake-parts.lib.mkFlake { inherit inputs; } (inputs.import-tree ./modules);

  nixConfig = {
    extra-experimental-features = "nix-command flakes";

    extra-substituters = [
      "https://nix-community.cachix.org/"
      "https://nixpkgs-python.cachix.org"
      "https://attic.desertflood.com/df-test"
    ];

    extra-trusted-public-keys = [
      "nix-community.cachix.org-1:mB9FSh9qf2dCimDSUo8Zy7bkq5CX+/rkCWyvRCYg3Fs="
      "nixpkgs-python.cachix.org-1:hxjI7pFxTyuTHn2NkvWCrAUcNZLNS3ZAvfYNuYifcEU="
      "df-test:nGcIjsIXVK/SZON7K4/IVCJPZ2PjNSRFyB2RBDHMPsU="
    ];
  };

  inputs = {
    flake-utils = {
      url = "github:numtide/flake-utils";
      inputs.systems.follows = "systems";
    };
    agenix = {
      url = "github:ryantm/agenix";
      inputs = {
        darwin.follows = "darwin";
        home-manager.follows = "home-manager";
        nixpkgs.follows = "nixpkgs";
        systems.follows = "systems";
      };
    };
    agenix-rekey = {
      url = "github:oddlama/agenix-rekey";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        devshell.follows = "devshell";
        flake-parts.follows = "flake-parts";
        pre-commit-hooks.follows = "pre-commit-hooks";
        treefmt-nix.follows = "treefmt-nix";
      };
    };
    darwin = {
      url = "github:nix-darwin/nix-darwin/nix-darwin-25.11";
      inputs.nixpkgs.follows = "nixpkgs-darwin";
    };
    dendrix = {
      url = "github:vic/dendrix";
      inputs.import-tree.follows = "import-tree";
      inputs.nixpkgs-lib.follows = "nixpkgs-lib";
    };
    devshell = {
      url = "github:numtide/devshell";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    disko = {
      url = "github:nix-community/disko";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixos-facter-modules.url = "github:numtide/nixos-facter-modules";
    flake-compat.url = "github:edolstra/flake-compat";
    flake-file = {
      url = "github:vic/flake-file";
    };
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs-lib";
    };
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    import-tree = {
      url = "github:vic/import-tree";
    };
    nixpkgs = {
      url = "github:nixos/nixpkgs/nixos-25.11";
    };
    nixpkgs-darwin = {
      url = "github:nixos/nixpkgs/nixpkgs-25.11-darwin";
    };
    nixpkgs-lib.url = "github:nix-community/nixpkgs.lib";
    pkgs-by-name-for-flake-parts.url = "github:drupol/pkgs-by-name-for-flake-parts";
    pre-commit-hooks = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs = {
        flake-compat.follows = "flake-compat";
        nixpkgs.follows = "nixpkgs";
      };
    };
    systems = {
      url = "github:jmartindf/nix-systems-modern-default";
    };
    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    deploy-rs = {
      url = "github:serokell/deploy-rs";
      inputs = {
        flake-compat.follows = "flake-compat";
        nixpkgs.follows = "nixpkgs";
      };
    };
    authentik-nix = {
      # url = "github:nix-community/authentik-nix/version/2025.10.3";
      url = "github:jmartindf/authentik-nix/60bc7431ccb809fc0311bfb3751660ee69eb1eb0";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-parts.follows = "flake-parts";
        flake-compat.follows = "flake-compat";
        flake-utils.follows = "flake-utils";
        systems.follows = "systems";
      };
    };
  };
}
