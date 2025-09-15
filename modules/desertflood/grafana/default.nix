_: {
  flake.modules.nixos.grafana =
    { config, ... }:
    let
      cfg = config;
      netCfg = cfg.desertflood.networking;
      promCfg = config.services.prometheus;
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

              provision = {
                enable = true;

                datasources.settings.datasources = [
                  {
                    orgId = 1;
                    name = "prometheus";
                    type = "prometheus";
                    httpMethod = "POST";
                    prometheusVersion = "> 2.50.x";
                    prometheusType = "Prometheus";
                    cacheLevel = "Low";
                    tlsSkipVerify = false;
                    manageAlerts = true;
                    url = "https://${promCfg.listenAddress}:${builtins.toString promCfg.port}/prometheus/";
                  }
                ];

                dashboards.settings.providers = [
                  {
                    name = "default";
                    orgId = 1;
                    type = "file";
                    disableDeletion = false;
                    updateIntervalSeconds = 10;
                    allowUiUpdates = true;
                    options = {
                      path = ./dashboards;
                      foldersFromFilesStructure = true;
                    };
                  }
                ];

              }; # end `provision` block

            }; # end `grafana` block

          }; # end `services` block

      }; # end Nix OS module config block

    }; # end `grafana` Nix OS module
}
