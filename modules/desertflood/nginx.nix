{ config, ... }:
let
  flakeCfg = config;
in
{
  flake.modules.nixos.nginx =
    _:
    let
      inherit (flakeCfg.desertflood.networking) webHost;
    in
    {
      options = {
      };

      config = {

        security.acme.certs.${webHost}.listenHTTP = null;

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
