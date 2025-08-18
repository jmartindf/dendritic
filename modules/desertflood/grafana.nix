_: {
  flake.modules.nixos.grafana =
    { config, ... }:
    let
      cfg = config;
      netCfg = cfg.desertflood.networking;
      inherit (config.desertflood.networking) webHost;
    in
    {
      options = {
      };

      config = {

        desertflood.networking.services.grafana = { };

        services =
          let
            svcConfig = netCfg.services.grafana;
          in
          {

            grafana = {
              enable = true;

              settings.server = {
                http_addr = "127.0.0.1";
                http_port = 3000;
                domain = "${svcConfig.fqdn}";
                root_url = "${svcConfig.fullURL}";
                serve_from_sub_path = if svcConfig.path != "" then true else false;
              };
            }; # end `grafana` block

          }; # end `services` block

      }; # end Nix OS module config block

    }; # end `grafana` Nix OS module
}
