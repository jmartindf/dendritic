{ config, lib, ... }:
let
  flakeCfg = config;
in
{
  flake.modules.nixos.node_exporter =
    { config, ... }:
    let
      cfg = config;
      inherit (cfg.desertflood.hostInfo) hostName;
      inherit (cfg.desertflood.services.prometheus.exporters.node) mTLS-required;
      certInfo = cfg.desertflood.step-ca.certInfo.${hostName};

      client_auth_type =
        if mTLS-required then "RequireAndVerifyClientCert" else "VerifyClientCertIfGiven";

      web-config = # yaml
        ''
          tls_server_config:
            # This is the server certificate for your `node-exporter` instance.
            cert_file: "${certInfo.cert_file}"
            key_file: "${certInfo.key_file.node-exporter}"

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

      config =
        let
          fragment = "prometheus-node-exporter";
          user = "node-exporter";
          group = "node-exporter";
        in
        {

          desertflood.step-ca.certs.${hostName}.availableTo = {
            node-exporter = {
              group = "node-exporter";
              reloadServices = [ "prometheus-node-exporter" ];
            };
          };

          services = {
            prometheus.exporters = {
              node = {
                enable = true;

                enabledCollectors = [
                  "systemd"
                  "processes"
                ];

                extraFlags = [
                  "--web.config.file=/etc/${fragment}/web-config.yml"
                  "--collector.filesystem.mount-points-exclude=\"^/(dev|proc|sys|run|nix)\""
                ];
              };
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
