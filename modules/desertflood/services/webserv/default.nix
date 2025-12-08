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

          desertflood.services.webserv = {
            enable = lib.mkEnableOption "integrated services to upload, manage, and serve files on the web";
          };
        };

        config =
          let
            groupName = "webserv";
            webFolder = dfCfg.globals.paths.staticHTML;
            caddyPort = toString dfCfg.globals.ports.caddy-static;
          in
          lib.mkIf svcsConfig.webserv.enable {

            # Create the shared group
            users.groups.${groupName} = { };

            # Enable SFTPGo for file management
            desertflood.services.sftpgo.enable = true;

            # SFTPGo gets read/write access to the folder
            services.sftpgo.extraReadWriteDirs = [ webFolder ];

            systemd.services = {
              # Add Caddy to the group, for read-only access to the folder
              caddy.serviceConfig.SupplementaryGroups = [ groupName ];

              # Add SFTPGo to the group, for read-write access to the folder
              sftpgo.serviceConfig.SupplementaryGroups = [ groupName ];

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
                                shutil.chown(
                                    webservFolder, user="${nixOScfg.services.sftpgo.user}", group="${groupName}"
                                )
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

            # Create a template for caddy, pointing to the folder
            desertflood.services.caddy.settings.site-blocks = # caddy
              ''
                (local-static) {
                  http://{args[0]}:${caddyPort} {
                    bind 127.0.0.1
                    cache
                    log

                    @no_ext {
                      path_regexp .*\/[^.]+$
                    }

                    root * ${webFolder}/{args[1]}

                    try_files {path} {path}/ {path}/index.html
                    header @no_ext ?Content-Type text/html
                    file_server {
                      disable_canonical_uris
                    }
                  }
                }
              '';
          };

      };

  };
}
