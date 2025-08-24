{ config, lib, ... }:
let
  flakeCfg = config;
in
{

  flake.modules.nixos.prometheus =
    { config, ... }:
    let
      cfg = config;
      webHost = "${config.networking.hostName}.${flakeCfg.desertflood.networking.tailscaleDomain}";
      inherit (cfg.desertflood.hostInfo) hostName;
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

          desertflood.step-ca.certs.${hostName}.availableTo = {
            prometheus = {
              group = "prometheus";
              reloadServices = [ "prometheus" ];
            };
            scrapeConfigs = [
          };

          services = {

            prometheus = {
              enable = true;
              listenAddress = "127.0.0.1";
              port = 9001;
              webExternalUrl = "http://${webHost}/prometheus/";

              extraFlags = [
                "--web.config.file=/etc/${fragment}/web-config.yml"
              ];

              globalConfig = {
                scrape_interval = "15s";
              };

                  {
                    job_name = "${config.networking.hostName}_http";
                    scheme = "http";
                    static_configs = [
                      {
                        labels = {
                          job = "node";
                        };
                        targets = lib.concatMap (item: [ "${item}:9100" ]) cfg.desertflood.services.prometheus.monitorHosts;
                      }
                    ];
                  }
                  {
                    job_name = "${config.networking.hostName}_https";
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
