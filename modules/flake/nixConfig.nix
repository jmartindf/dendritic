_: {
  flake-file.nixConfig = {
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
}
