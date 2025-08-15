_: {
  flake.modules.nixos.nginx = _: {
    options = {
    };

    config = {

      services.nginx = {
        enable = true;
        defaultListenAddresses = [ "0.0.0.0" ];
        recommendedTlsSettings = true;
        recommendedOptimisation = true;
        recommendedGzipSettings = true;
        recommendedZstdSettings = true;
        recommendedBrotliSettings = true;
      }; # end `services.nginx` block

    }; # end Nix OS module config block

  }; # end `nginx` Nix OS module
}
