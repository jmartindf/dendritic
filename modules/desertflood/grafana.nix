{ config, ... }:
let
  flakeCfg = config;
in
{
  flake.modules.nixos.grafana =
    _:
    let
      inherit (flakeCfg.desertflood.networking) webHost;
    in
    {
      options = {
      };

      config = {

        services = {

          grafana = {
            enable = true;

            settings.server = {
              http_addr = "127.0.0.1";
              http_port = 3000;
              domain = "${webHost}";
              root_url = "https://${webHost}/grafana/";
              serve_from_sub_path = true;
            };
          }; # end `grafana` block

        }; # end `services` block

      }; # end Nix OS module config block

    }; # end `grafana` Nix OS module
}
