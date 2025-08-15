{ config, lib, ... }:
let
  flakeCfg = config;
in
{
  flake.modules.nixos.prometheus =
    { config, pkgs, ... }:
    let
      cfg = config;
      webHost = "${config.networking.hostName}.${flakeCfg.desertflood.networking.tailscaleDomain}";
      inherit (cfg.desertflood.services.prometheus) mTLS-required;
      nodeStem = "prometheus";
      user = "prometheus";
      group = "prometheus";
      etcPath = "/etc/${nodeStem}";
      certPath = "${etcPath}/${nodeStem}.cert";
      keyPath = "${etcPath}/${nodeStem}.key";

      client_auth_type =
        if mTLS-required then "RequireAndVerifyClientCert" else "VerifyClientCertIfGiven";

      prometheus_cert_init_script = # bash
        ''
          mkdir -p ${etcPath}
          if [ ! -f ${certPath} ]; then
            step ca certificate \
                --provisioner "${flakeCfg.desertflood.step-ca.provisioner}" \
                --provisioner-password-file="${cfg.age.secrets.provisioner-password.path}" \
                "${cfg.networking.hostName}" \
                ${certPath} \
                ${keyPath} \
                --san "${cfg.networking.fqdn}" \
                --san "${cfg.networking.hostName}.${flakeCfg.desertflood.networking.tailscaleDomain}" \
                --not-after 24h || exit 1
            chown ${user}:${group} ${certPath} ${keyPath}
          fi
        '';

      prometheus_cert_renew_script = # bash
        ''
          step ca renew \
              --force \
              --expires-in 10h \
              --exec="systemctl reload-or-restart prometheus" \
              ${certPath} \
              ${keyPath} || exit 1
        '';

      web-config = # yaml
        ''
          tls_server_config:
            # This is the server certificate for your `prometheus` server.
            cert_file: "${certPath}"
            key_file: "${keyPath}"

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
            http2: false
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

      config = {

        services = {

          prometheus = {
            enable = true;
            listenAddress = "127.0.0.1";
            port = 9001;
            webExternalUrl = "http://${webHost}/prometheus/";

            extraFlags = [
              "--web.config.file=${etcPath}/web-config.yml"
            ];

            globalConfig = {
              scrape_interval = "15s";
            };

            scrapeConfigs = [
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

        environment.etc."${nodeStem}/web-config.yml" = {
          text = web-config;
          inherit user group;
          mode = "0664";
        };

        systemd.services = {
          "prometheus-cert-init" = {
            description = "Create a TLS certificate for Prometheus";

            wants = [
              "network.target"
              "network-online.target"
            ];

            after = [
              "network.target"
              "network-online.target"
            ];

            serviceConfig.Type = "oneshot";

            before = [ "prometheus.service" ];
            requiredBy = [ "prometheus.service" ];

            environment = {
              STEPPATH = "/etc/step-ca";
            };
            path = [ pkgs.step-cli ];
            enableStrictShellChecks = true;
            script = prometheus_cert_init_script;
          };

          "prometheus-cert-renew" = {
            description = "Renew the TLS certificate for Prometheus";

            wants = [
              "network.target"
              "network-online.target"
            ];

            after = [
              "network.target"
              "network-online.target"
            ];

            serviceConfig.Type = "oneshot";

            environment = {
              STEPPATH = "/etc/step-ca";
            };
            path = [ pkgs.step-cli ];
            enableStrictShellChecks = true;
            script = prometheus_cert_renew_script;
          };
        };

        systemd.timers = {
          "prometheus-cert-renew" = {
            wantedBy = [ "timers.target" ];
            partOf = [ "prometheus-cert-renew.service" ];
            timerConfig = {
              OnCalendar = "2/6:5:5"; # every 6 hours, 5 minutes and 5 seconds past the hour
              Unit = "prometheus-cert-renew.service";
            };
          };
        };

      };
    };
}
