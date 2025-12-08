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
        dfSvcsConfig = dfCfg.services;
        netCfg = dfCfg.networking;
        dfSvcsNetCfg = netCfg.services;
        sftpCfg = nixOScfg.services.sftpgo;
        sftpgoUser = sftpCfg.user;
        sftpgoGroup = sftpCfg.group;

        certFolder = "/etc/ssh";
        keyFile = "ssh_host_ed25519_key";
        certFile = "ssh_host_ed25519_key-cert.pub";
        svcFolder = "/var/lib/sftpgo";
      in
      {

        imports = [ ];

        options = {

          desertflood.services.sftpgo = {
            enable = lib.mkEnableOption "SFTPGo file uploads";
            port = lib.mkOption {
              type = lib.types.port;
              default = dfCfg.globals.ports.sftpgo-http;
              description = "The port for serving HTTP(S) requests";
            };
          };
        };

        config = lib.mkIf dfSvcsConfig.sftpgo.enable {

          # TODO: Configure scheduled job for updating quotas?

          desertflood.networking.services.sftpgo = { };

          services.postgresql = {
            enable = true;
            ensureDatabases = [ sftpgoUser ];
            ensureUsers = [
              {
                name = sftpgoUser;
                ensureDBOwnership = true;
              }
            ];
          };

          services.sftpgo = {
            enable = true;

            settings = {
              common = {
                # owner[sftpgo] can read & write
                # group[webserv] can only read
                # everyone else can pound sand
                umask = "027";
              };

              data_provider = {
                driver = "postgresql";
                name = sftpgoUser;
                host = "/var/run/postgresql";
                username = sftpgoUser;
                track_quota = 1; # updated each time a user uploads or deletes a file, even if the user has no quota restrictions
                delayed_quota_update = 5; # only every 5 seconds
                # Configure home directory for (virtual) users
                users_base_dir = "${svcFolder}/homes";
              };

              sftpd = {
                bindings = [
                  {
                    address = ""; # available on all interfaces / addresses
                    port = 21; # take over the traditional FTP port
                  }
                ];

                host_keys = [ "${svcFolder}/${keyFile}" ];
                host_certificates = [ "${svcFolder}/${certFile}" ];
                # trusted_user_ca_keys = [ ];
                kex_algorithms = [
                  "mlkem768x25519-sha256"
                  "curve25519-sha256"
                  "diffie-hellman-group-exchange-sha256"
                ];
                ciphers = [
                  "chacha20-poly1305@openssh.com"
                  "aes256-gcm@openssh.com"
                  "aes128-gcm@openssh.com"
                  "aes128-ctr"
                ];
                macs = [
                  "hmac-sha2-512-etm@openssh.com"
                  "hmac-sha2-256-etm@openssh.com"
                ];
              };

              httpd = {
                bindings = [
                  {
                    enable_web_client = true;
                    enable_web_admin = true;
                    address = "127.0.0.1"; # localhost only, proxy through Traefik
                    inherit (dfSvcsConfig.sftpgo) port;
                    proxy_allowed = "127.0.0.1";
                    client_ip_proxy_header = "X-Real-IP";
                  }
                ];
                web_root = "${dfSvcsNetCfg.sftpgo.path}";
                cookie_lifetime = 720; # valid for 12 hours
              };
            };
          };

          systemd = {

            services.sftpgo = {
              serviceConfig = {
                StateDirectory = lib.mkForce "sftpgo sftpgo/homes";
              };
              after = [
                "postgresql.target"
                "sftpgo-ssh-certificate-sync.service"
              ];
              requires = [
                "postgresql.target"
                "sftpgo-ssh-certificate-sync.service"
              ];
            };

            paths.sftpgo-ssh-certificate-sync = {
              description = "Update SFTPGo's SSH certificate whenever OpenSSH's certificate is renewed.";
              pathConfig = {
                PathChanged = "${certFolder}/${certFile}";
                PathModified = "${certFolder}/${certFile}";
              };
            };

            services.sftpgo-ssh-certificate-sync = {
              description = "Update SFTPGo's SSH certificate whenever OpenSSH's certificate is renewed.";

              wants = [ "network.target" ];

              after = [
                "network.target"
                "sshd.service"
                "sshd@.service"
              ];

              wantedBy = [
                "multi-user.target"
                "sftpgo.service"
              ];

              before = [ "sftpgo.service" ];

              serviceConfig = {
                type = "oneshot";

                User = "root";
                Group = "root";

                ExecStart =
                  let
                    privilegedSetupScript =
                      pkgs.writers.writePython3Bin "sftpgo-certs_and_keys-setup" { }
                        # python
                        ''
                          import shutil
                          from pathlib import Path

                          keyName = "${keyFile}"
                          certName = "${certFile}"

                          sourceFolder = "${certFolder}"
                          destFolder = "${svcFolder}"

                          sourceKey = Path(f"{sourceFolder}/{keyName}")
                          sourceCertificate = Path(f"{sourceFolder}/{certName}")
                          destKey = Path(f"{destFolder}/{keyName}")
                          destCertificate = Path(f"{destFolder}/{certName}")

                          # If the key exists and hasn't already been copied over
                          # It's never regenerated, so no need to copy it over each time
                          if sourceKey.is_file() and not destKey.is_file():
                              destKey.unlink(missing_ok=True)
                              shutil.copy2(sourceKey, destKey)
                              shutil.chown(destKey, user="${sftpgoUser}", group="${sftpgoGroup}")

                          # We only care that the certificate exists. It gets regenerated so often
                          # that it makes sense to copy it every time
                          if sourceCertificate.is_file():
                              destCertificate.unlink(missing_ok=True)
                              shutil.copy2(sourceCertificate, destCertificate)
                              shutil.chown(destCertificate, user="${sftpgoUser}", group="${sftpgoGroup}")
                        '';
                  in
                  "+${privilegedSetupScript}/bin/sftpgo-certs_and_keys-setup";

                # Security hardening
                ReadWritePaths = [ svcFolder ]; # need to be able to write to the destination dir
                PrivateTmp = true;
                ProtectSystem = "strict";
                ProtectKernelTunables = true;
                ProtectKernelModules = true;
                ProtectControlGroups = true;
                ProtectHome = "read-only";
                PrivateDevices = true;
              };
            };
          };

        };
      };
  };
}
