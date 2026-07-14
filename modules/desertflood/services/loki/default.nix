{
  inputs,
  config,
  lib,
  ...
}:
let
  flakeCfg = config;
in
{
  # SPDX-FileCopyrightText: 2025 Joe Martin <joe@desertflood.com>
  # SPDX-License-Identifier: BlueOak-1.0.0

  imports = [ ];

  options = { };

  config = {

    flake.modules.nixos.services =
      {
        lib,
        pkgs,
        config,
        ...
      }:
      let
        nixOScfg = config;
        dfCfg = nixOScfg.desertflood;
        netCfg = dfCfg.networking;
        svcsConfig = dfCfg.services;
        svcsNetCfg = netCfg.services;
      in
      {

        imports = [ ];

        options = {

          desertflood.services.loki = {
            enable = lib.mkEnableOption "Whether to enable Grafana Loki - like Prometheus, but for logs.";

            port = lib.mkOption {
              type = lib.types.port;
              description = "Local port Loki listens on for HTTP connections";
              default = dfCfg.globals.ports.loki;
            };

            loglevel = lib.mkOption {
              type = lib.types.enum [
                "debug"
                "info"
                "warn"
                "error"
              ];
              default = "warn";
              description = "How many log entries should Loki generate";
            };
          };
        };

        config = lib.mkIf svcsConfig.loki.enable {

          desertflood.networking.services.loki = { };

          services.loki =
            let
              inherit (svcsConfig.loki) port;
              # gRPCPort = 9096;
              listen_on = "127.0.0.1";
              path = nixOScfg.services.loki.dataDir;
            in
            {
              enable = true;

              configuration = {
                auth_enabled = false;

                server = {
                  http_listen_port = port;
                  log_level = "${svcsConfig.loki.loglevel}";
                  # grpc_listen_port = gRPCPort;
                  # grpc_server_max_concurrent_streams = 1000;
                };

                common = {
                  instance_addr = "${listen_on}";
                  path_prefix = "${path}";
                  replication_factor = 1;
                  ring.kvstore.store = "inmemory";

                  storage.filesystem = {
                    chunks_directory = "${path}/chunks";
                    rules_directory = "${path}/rules";
                  };
                };

                query_range.results_cache.cache.embedded_cache = {
                  enabled = true;
                  max_size_mb = 100;
                };

                limits_config = {
                  metric_aggregation_enabled = true;
                  enable_multi_variant_queries = true;
                  max_query_lookback = "672h"; # 4 weeks
                  retention_period = "672h"; # 4 weeks
                };

                compactor = {
                  working_directory = "${path}/data/retention";
                  compaction_interval = "10m";
                  retention_enabled = true;
                  retention_delete_delay = "2h";
                  delete_request_cancel_period = "2h"; # Why wait 24 hours before processing deletes?
                  retention_delete_worker_count = 25;
                  delete_request_store = "filesystem";
                };

                schema_config.configs = [
                  {
                    from = "2025-12-01";
                    store = "tsdb";
                    object_store = "filesystem";
                    schema = "v13";
                    index = {
                      prefix = "index_";
                      period = "24h";
                    };
                  }
                ];

                pattern_ingester = {
                  enabled = true;
                  metric_aggregation.loki_address = "${listen_on}:${builtins.toString port}";
                };

                # ruler = {
                #   alertmanager_url = "http://${listen_on}:9093";
                # };

                frontend = {
                  encoding = "protobuf";
                };

                # By default, Loki will send anonymous, but uniquely-identifiable usage and configuration
                # analytics to Grafana Labs. These statistics are sent to https://stats.grafana.org/
                #
                # Statistics help us better understand how Loki is used, and they show us performance
                # levels for most users. This helps us prioritize features and documentation.
                # For more information on what's sent, look at
                # https://github.com/grafana/loki/blob/main/pkg/analytics/stats.go
                # Refer to the buildReport method to see what goes into a report.
                #
                # If you would like to disable reporting, uncomment the following line:
                # analytics.reporting_enabled = false;
              };
            };

        };

      };

  };

}
