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

      networking.firewall.allowedTCPPorts = [
        80
        443
      ];

    }; # end Nix OS module config block

  }; # end `nginx` Nix OS module
}
