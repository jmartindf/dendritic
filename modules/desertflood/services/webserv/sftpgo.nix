# SPDX-FileCopyrightText: 2025 Joe Martin <joe@desertflood.com>
# SPDX-License-Identifier: BlueOak-1.0.0
_: {
  df.services.webserv = {

    nixos =
      {
        pkgs,
        config,
        ...
      }:
      let
        groupName = "webserv";
        userName = config.services.sftpgo.user;
        webFolder = config.desertflood.globals.paths.staticHTML;
      in
      {

        systemd.services = {
          # Make sure the shared folder is created before SFTPGo starts
          prep-webserv-folder = {
            description = "Create ${webFolder} and share it between Caddy and SFTPGo.";

            wants = [ "network.target" ];
            after = [
              "network.target"
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
                    pkgs.writers.writePython3Bin "sftpgo-webserv-setup" { }
                      # python
                      ''
                        import shutil
                        from pathlib import Path

                        webservFolder = Path("${webFolder}")

                        # Make sure the directory exists
                        # If not, create it with the correct ownership
                        if not webservFolder.is_dir():
                            webservFolder.mkdir(parents=True)

                            # u+rwx,g+rs,o-rwx
                            webservFolder.chmod(0o2750)

                            # owner = SFTPGo user
                            # group = webserv group
                            shutil.chown(webservFolder, user="${userName}", group="${groupName}")
                      '';
                in
                "+${privilegedSetupScript}/bin/sftpgo-webserv-setup";

              # Security hardening
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
}
