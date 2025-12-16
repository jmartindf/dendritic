{ lib, ... }:
{

  flake.modules.nixos.prometheus =
    { config, ... }:
    let
      cfg = config;
      netCfg = cfg.desertflood.networking;
      inherit (cfg.networking) hostName;
      inherit (cfg.desertflood.services.prometheus) mTLS-required;
      certInfo = cfg.desertflood.step-ca.certInfo.${hostName};

      client_auth_type =
        if mTLS-required then "RequireAndVerifyClientCert" else "VerifyClientCertIfGiven";

      web-config = # yaml
        ''
          tls_server_config:
            # This is the server certificate for your `prometheus` server.
            cert_file: "${certInfo.cert_file}"
            key_file: "${certInfo.key_file.prometheus}"

            # request a client certificate during the handshake
            # if the client does send a certificate it is required to be valid
            # for VerifyClientCertIfGiven, the client is not required to send a certificate
            # for RequireAndVerifyClientCert, the client must send a certificate
            client_auth_type: "${client_auth_type}"

            # This is the CA the client certificate must be signed by.
            client_ca_file: "/etc/step-ca/certs/root_ca.crt"

          http_server_config:
            # Enable HTTP/2 support. Note that HTTP/2 is only supported with TLS.
            # This can not be changed on the fly.
            http2: true
        '';
    in
    {
      options = {
        desertflood.services.prometheus = {

          mTLS-required = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Require mutual TLS authentication to access Prometheus";
          };

          monitorHosts = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            description = "Hosts to scrape";
          };

          monitorHostsSecure = lib.mkOption {
            type = lib.types.listOf lib.types.str;
            description = "Hosts to scrape via HTTPs";
          };

        };
      };

      config =
        let
          fragment = "prometheus";
          user = fragment;
          group = fragment;
        in
        {

          desertflood.networking.services.prometheus = { };

          desertflood.step-ca.certs.${hostName}.availableTo = {
            prometheus = {
              group = "prometheus";
              reloadServices = [ "prometheus" ];
            };
          };

          services = {

            prometheus = {
              enable = true;
              listenAddress = "127.0.0.1";
              port = 9001;
              webExternalUrl = "${netCfg.services.prometheus.fullURL}";

              extraFlags = [
                "--web.config.file=/etc/${fragment}/web-config.yml"
                "--web.enable-remote-write-receiver"
              ];

              globalConfig = {
                scrape_interval = "15s";
              };

              scrapeConfigs =
                let
                  basic_relabel = [
                    {
                      source_labels = [ "nodename" ];
                      target_label = "nodename";
                      action = "lowercase";
                    }
                    {
                      source_labels = [ "nodename" ];
                      regex = "^([^\.]+).*";
                      target_label = "nodename";
                      replacement = "\$1";
                    }
                    {
                      source_labels = [ "instance" ];
                      regex = "^([^\.]+).*";
                      target_label = "instance";
                      replacement = "\$1";
                    }
                    {
                      source_labels = [ "instance" ];
                      regex = "^127$";
                      target_label = "instance";
                      replacement = "${hostName}";
                    }
                    # {
                    #   source_labels = [ "domainname" ];
                    #   action = "drop";
                    # }
                  ];
                in
                [
                  {
                    job_name = "${hostName}_http";
                    scheme = "http";
                    static_configs = [
                      {
                        labels = {
                          job = "node";
                        };
                        targets = lib.concatMap (item: [ "${item}:9100" ]) cfg.desertflood.services.prometheus.monitorHosts;
                      }
                    ];
                    metric_relabel_configs = basic_relabel;
                  }
                  {
                    job_name = "${hostName}_https";
                    scheme = "https";
                    static_configs = [
                      {
                        labels = {
                          job = "node";
                        };
                        targets = lib.concatMap (item: [
                          "${item}:9100"
                        ]) cfg.desertflood.services.prometheus.monitorHostsSecure;
                      }
                    ];
                    metric_relabel_configs = basic_relabel;
                  }
                ];

            };
          };

          environment.etc."${fragment}/web-config.yml" = {
            text = web-config;
            inherit user group;
            mode = "0664";
          };

          systemd.services.${fragment} = {
            requires = [ "smallstep-order-renew-${hostName}.service" ];
            after = [ "smallstep-order-renew-${hostName}.service" ];
          };

        };
    };
}
