_: {

  config = {

    flake.modules.nixos.step-ca =
      {
        config,
        lib,
        # pkgs,
        ...
      }:
      let
        nixOScfg = config;
        stepUser = "step-ca";

        # settingsFormat = (pkgs.formats.json { });

        svcsConfig = nixOScfg.desertflood.services;
        netConfig = nixOScfg.desertflood.networking;

        mkStepSecrets =
          secretHolder: names:
          lib.genAttrs names (name: {
            rekeyFile = ./secrets/${name}.age;
            owner = secretHolder;
            group = secretHolder;
          });
      in
      {

        imports = [ ];

        options = {
          desertflood.services.step-ca = {

            enable = lib.mkEnableOption {
              default = false;
              description = "Whether to enable step-ca, an open source certificate management toolchain";
            };

            # setting for dns names
            fqdns = lib.mkOption {
              type = lib.types.listOf lib.types.str;
              description = "The FQDNs for accessing the Smallstep PKI";
            };

            address = lib.mkOption {
              type = lib.types.str;
              example = "127.0.0.1";
              description = ''
                The address (without port) the certificate authority should listen at.
                This combined with {option}`desertflood.services.step-ca.port` overrides {option}`services.step-ca.settings.address`.
              '';
              default = "127.0.0.1";
            };

            port = lib.mkOption {
              type = lib.types.port;
              example = 8443;
              description = ''
                The port the certificate authority should listen on.
                This combined with {option}`desertflood.services.step-ca.address` overrides {option}`services.step-ca.settings.address`.
              '';
              default = 8443;
            };

          };
        }; # end NixOS module `options`

        config = lib.mkIf svcsConfig.step-ca.enable {

          age.secrets = mkStepSecrets stepUser [
            "step-ca-intermediate_ca_key"
            "step-ca-ssh_host_ca_key"
            "step-ca-ssh_user_ca_key"
            "step-ca-intermediate_password"
          ];

          desertflood.networking.services.step-ca = { };

          desertflood.services.step-ca = {
            fqdns = [
              netConfig.FQDN
              netConfig.tsFQDN
              "127.0.0.1"
            ];
          };

          services.step-ca = {
            enable = true;

            intermediatePasswordFile = nixOScfg.age.secrets.step-ca-intermediate_password.path;

            inherit (svcsConfig.step-ca) address port;

            settings =
              let
                rootPath = "/var/lib/step-ca";
              in
              {
                root = ./certs/step-ca-root_ca.crt;
                # federatedRoots = null;

                crt = ./certs/step-ca-intermediate_ca.crt;
                key = nixOScfg.age.secrets.step-ca-intermediate_ca_key.path;

                dnsNames = svcsConfig.step-ca.fqdns;

                ssh = {
                  hostKey = nixOScfg.age.secrets.step-ca-ssh_host_ca_key.path;
                  userKey = nixOScfg.age.secrets.step-ca-ssh_user_ca_key.path;
                };

                logger.format = "text";

                db = {
                  type = "badgerv2";
                  dataSource = "${rootPath}/db";
                  badgerFileLoadingMode = "MemoryMap";
                };

                authority.enableAdmin = true;

                tls = {

                  cipherSuites = [
                    "TLS_ECDHE_ECDSA_WITH_CHACHA20_POLY1305_SHA256"
                    "TLS_ECDHE_ECDSA_WITH_AES_128_GCM_SHA256"
                  ];

                  minVersion = 1.2;
                  maxVersion = 1.3;
                  renegotiation = false;
                };

                templates = {

                  ssh = {

                    user = [
                      {
                        name = "config.tpl";
                        type = "snippet";
                        template = ./templates/ssh/config.tpl;
                        path = "~/.ssh/config";
                        comment = "#";
                      }
                      {
                        name = "step_includes.tpl";
                        type = "prepend-line";
                        template = ./templates/ssh/step_includes.tpl;
                        path = "\${STEPPATH}/ssh/includes";
                        comment = "#";
                      }
                      {
                        name = "step_config.tpl";
                        type = "file";
                        template = ./templates/ssh/step_config.tpl;
                        path = "ssh/config";
                        comment = "#";
                      }
                      {
                        name = "known_hosts.tpl";
                        type = "file";
                        template = ./templates/ssh/known_hosts.tpl;
                        path = "ssh/known_hosts";
                        comment = "#";
                      }
                    ]; # end `templates.ssh.user`

                    host = [
                      {
                        name = "sshd_config.tpl";
                        type = "snippet";
                        template = ./templates/ssh/sshd_config.tpl;
                        path = "/etc/ssh/sshd_config";
                        comment = "#";
                        requires = [
                          "Certificate"
                          "Key"
                        ];
                      }
                      {
                        name = "ca.tpl";
                        type = "snippet";
                        template = ./templates/ssh/ca.tpl;
                        path = "/etc/ssh/ca.pub";
                        comment = "#";
                      }
                    ]; # end `templates.ssh.host`

                  }; # end `templates.ssh`
                }; # end `templates`

              }; # end services.step-ca.settings

          }; # end services.step-ca

          environment.etc = {
            "step-ca/certs/ssh_host_ca_key.pub".source = ./certs/ssh_host_ca_key.pub;
            "step-ca/certs/ssh_user_ca_key.pub".source = ./certs/ssh_user_ca_key.pub;

            # `step` CLI default configuration
            #  "smallstep/defaults.json".source = settingsFormat.generate "defaults.json" {
            #    ca-url = "https://pki.desertflood.link";
            #    ca-config = "/etc/smallstep/ca.json";
            #    fingerprint = "be95020a50bc30002b6f5a2ea3cd827b169412235192adeb3296a827d0036e00";
            #    root = nixOScfg.age.secrets.step-ca-root_ca_crt.path;
            #  };
          };

        }; # end NixOS module `config`

      }; # end NixOS `step-ca` module

  }; # End flake-parts `config`

}
