{ config, lib, ... }:
let
  flakeCfg = config;
in
{
  flake.modules.nixos.node_exporter =
    { config, pkgs, ... }:
    let
      cfg = config;
      inherit (cfg.desertflood.services.prometheus.exporters.node) mTLS-required;
      nodeStem = "prometheus-node-exporter";
      user = "node-exporter";
      group = "node-exporter";
      etcPath = "/etc/${nodeStem}";
      certPath = "${etcPath}/${nodeStem}.cert";
      keyPath = "${etcPath}/${nodeStem}.key";

      client_auth_type =
        if mTLS-required then "RequireAndVerifyClientCert" else "VerifyClientCertIfGiven";

      node_cert_init_script = # bash
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

      node_cert_renew_script = # bash
        ''
          step ca renew \
              --force \
              --expires-in 10h \
              --exec="systemctl reload-or-restart prometheus-node-exporter" \
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
            http2: true
        '';
    in
    {
      options = {
        desertflood.services.prometheus.exporters.node = {

          mTLS-required = lib.mkOption {
            type = lib.types.bool;
            default = false;
            description = "Require mutual TLS authentication to scrape statistics";
          };

        };
      };

      config = {
        services = {
          prometheus.exporters = {
            node = {
              enable = true;

              enabledCollectors = [
                "systemd"
                "processes"
              ];

              extraFlags = [
                "--web.config.file=${etcPath}/web-config.yml"
              ];
            };
          };
        };

        environment.etc."${nodeStem}/web-config.yml" = {
          text = web-config;
          inherit user group;
          mode = "0664";
        };

        systemd.services = {
          "prometheus-node-exporter-cert-init" = {
            description = "Create a TLS certificate for node_exporter";

            wants = [
              "network.target"
              "network-online.target"
            ];

            after = [
              "network.target"
              "network-online.target"
            ];

            serviceConfig.Type = "oneshot";

            before = [ "prometheus-node-exporter.service" ];
            requiredBy = [ "prometheus-node-exporter.service" ];

            environment = {
              STEPPATH = "/etc/step-ca";
            };
            path = [ pkgs.step-cli ];
            enableStrictShellChecks = true;
            script = node_cert_init_script;
          };

          "prometheus-node-exporter-cert-renew" = {
            description = "Renew the TLS certificate for node_exporter";

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
            script = node_cert_renew_script;
          };
        };

        systemd.timers = {
          "prometheus-node-exporter-cert-renew" = {
            wantedBy = [ "timers.target" ];
            partOf = [ "prometheus-node-exporter-cert-renew.service" ];
            timerConfig = {
              OnCalendar = "2/6:5:5"; # every 6 hours, 5 minutes and 5 seconds past the hour
              Unit = "prometheus-node-exporter-cert-renew.service";
            };
          };
        };

      };
    };
}
