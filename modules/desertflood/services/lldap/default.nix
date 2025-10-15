_: {
  # SPDX-FileCopyrightText: 2025 Joe Martin <joe@desertflood.com>
  # SPDX-License-Identifier: BlueOak-1.0.0

  flake.modules.nixos.lldap =
    {
      config,
      lib,
      pkgs,
      ...
    }:
    let
      nixOScfg = config;
      netSvcsCfg = nixOScfg.desertflood.networking.services;
    in
    {
      imports = [ ];

      options = {
        desertflood.services.lldap = {
          enable = lib.mkEnableOption {
            description = "lldap, a lightweight authentication server that provides an opinionated, simplified LDAP interface for authentication";
            default = false;
          };
        };
      };

      config =
        let
          lldapUser = "lldap";
          mkSecrets =
            secretHolder: names:
            lib.genAttrs names (name: {
              rekeyFile = ./${name}.age;
              owner = secretHolder;
              group = secretHolder;
            });
        in
        lib.mkIf nixOScfg.desertflood.services.lldap.enable {

          desertflood = {

            shared-secrets.smtp.enable = true;

            networking.services.lldap = { };

            services = {
              postgresql.enable = true;
            };

          };

          age.secrets = {
            lldap-jwt-secret.rekeyFile = ./lldap-jwt-secret.age;
            lldap-key-seed.rekeyFile = ./lldap-key-seed.age;
            ldap-user-password.rekeyFile = ./ldap-user-password.age;
          };

          services = {

            lldap = {
              enable = true;

              settings = {
                ldap_host = "127.0.0.1";
                http_host = "127.0.0.1";
                http_url = "${netSvcsCfg.lldap.fullURL}";
                ldap_base_dn = "dc=desertflood,dc=com";
                ldap_user_dn = "admin";
                ldap_user_email = "admin@desertflood.com";
                key_file = "";
                database_url = "postgres://${lldapUser}@localhost/${lldapUser}?host=/run/postgresql/";

                smtp_options = {
                  enable_password_reset = true;
                  port = 587;
                  smtp_encryption = "TLS";
                  from = "Desertflood Homelab Admin <admin@thosemartins.family>";
                };
              };

              environment = {
                LLDAP_JWT_SECRET_FILE = "%d/CRED_JWT_SECRET";
                LLDAP_KEY_SEED_FILE = "%d/CRED_KEY_SEED";
                LLDAP_LDAP_USER_PASS_FILE = "%d/CRED_LDAP_USER_PASS";
                LLDAP_SMTP_OPTIONS__SERVER = "%d/CRED_SMTP_SERVER";
                LLDAP_SMTP_OPTIONS__USER = "%d/CRED_SMTP_USER";
                LLDAP_SMTP_OPTIONS__PASSWORD_FILE = "%d/CRED_SMTP_PASSWORD";
              };

            };

            postgresql = {
              authentication = ''
                local ${lldapUser} all peer map=lldap-users
              '';

              identMap = # identMap
                ''
                  lldap-users root ${lldapUser}
                  lldap-users ${lldapUser} ${lldapUser}
                '';

              ensureDatabases = [ lldapUser ];
              ensureUsers = [
                {
                  name = lldapUser;
                  ensureDBOwnership = true;
                }
              ];
            };
          };

          systemd.services = {

            postgresql = {
              before = [ "lldap.service" ];
            };

            lldap = {
              requires = [ "postgresql.service" ];

              serviceConfig = {
                # PrivateMounts = true;
                # BindReadOnlyPaths = [ "/run/credentials" ];

                LoadCredential =
                  let
                    vault = nixOScfg.age.secrets;
                  in
                  [
                    "CRED_JWT_SECRET:${vault.lldap-jwt-secret.path}"
                    "CRED_KEY_SEED:${vault.lldap-key-seed.path}"
                    "CRED_LDAP_USER_PASS:${vault.ldap-user-password.path}"
                    "CRED_SMTP_SERVER:${vault.smtp-server.path}"
                    "CRED_SMTP_USER:${vault.smtp-user.path}"
                    "CRED_SMTP_PASSWORD:${vault.smtp-password.path}"
                  ];
              };
            };
          };

        };

    };
}
