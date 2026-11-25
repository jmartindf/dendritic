# SPDX-FileCopyrightText: 2025 Joe Martin <joe@desertflood.com>
# SPDX-License-Identifier: BlueOak-1.0.0
{
  df,
  ...
}:
{
  df.services.webserv = {

    # Enable SFTPGo for file management
    includes = [
      df.services.caddy
      df.services.sftpgo
    ];

    nixos =
      {
        config,
        ...
      }:
      let
        groupName = "webserv";
        webFolder = config.desertflood.globals.paths.staticHTML;
      in
      {

        # Create the shared group
        users.groups.${groupName} = { };

        # SFTPGo gets read/write access to the folder
        services.sftpgo.extraReadWriteDirs = [ webFolder ];

        systemd.services = {
          # Add Caddy to the group, for read-only access to the folder
          caddy.serviceConfig.SupplementaryGroups = [ groupName ];

          # Add SFTPGo to the group, for read-write access to the folder
          sftpgo.serviceConfig.SupplementaryGroups = [ groupName ];
        };
      };
  };
}
