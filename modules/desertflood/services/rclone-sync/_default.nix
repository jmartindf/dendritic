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
        utils,
        ...
      }:
      let
        nixOScfg = config;
        dfCfg = nixOScfg.desertflood;
        netCfg = dfCfg.networking;
        svcsConfig = dfCfg.services;
        svcsNetCfg = netCfg.services;
        inherit (utils.systemdUtils.unitOptions) unitOption;
        rcloneCfg = svcsConfig.rclone-sync;
      in
      {

        imports = [ ];

        options = {

          desertflood.services.rclone-sync = lib.mkOption {
            description = ''
              Periodic copies of a local directory with an Rclone remote
            '';
            type = lib.types.attrsOf (
              lib.types.submodule (_: {
                options = {
                  enable = lib.mkEnableOption "Sync a local directory with a remote using Rclone";

                  direction = lib.mkOption {
                    type = lib.types.enum [
                      "up"
                      "down"
                    ];
                    description = "When syncing up, copy the local to the remote. When syncing down, copy the remote to the local";
                    default = "up";
                  };

                  dataDir = lib.mkOption {
                    type = lib.types.str;
                    description = "The local directory to be copied to/from.";
                    example = "/srv/restic";
                  };

                  environmentFile = lib.mkOption {
                    default = null;
                    type = lib.types.nullOr lib.types.str;
                    description = ''
                      Path to a file containing REMOTE (set to the full rclone destination,
                      e.g. `myremote:bucket/path`). If using Rclone env_auth (ie environmental variables)
                      to authenticate with remote, they should also be configured here
                    '';
                    example = "/var/run/agenix/rcloneRemoteDir";
                  };

                  extraRcloneArgs = lib.mkOption {
                    type = lib.types.listOf lib.types.str;
                    default = [
                      "--transfers=32"
                      "--b2-hard-delete"
                      "--fast-list"
                    ];
                    description = ''
                      Extra arguments passed to rclone
                    '';
                    example = [
                      "--transfers=32"
                      "--b2-hard-delete"
                      "--fast-list"
                    ];
                  };

                  rcloneConfFile = lib.mkOption {
                    type = lib.types.str;
                    description = "Path to `rclone.conf` file (must be readable by same user as this service)";
                    example = "/var/run/agenix/rcloneConf";
                    default = "/etc/rclone.conf";
                  };

                  timerConfig = lib.mkOption {
                    type = lib.types.nullOr (lib.types.attrsOf unitOption);
                    default = null;
                    description = ''
                      When to run rclone. See {manpage}`systemd.timer(5)` for
                      details. If null no timer is created and rclone will only
                      run when explicitly started.
                    '';
                    example = {
                      OnCalendar = "06:00";
                      RandomizedDelaySec = "1h";
                      Persistent = true;
                    };
                  };

                  package = lib.mkPackageOption pkgs "rclone" { };
                };
              })
            );
            default = { };
          };

          config = {
            assertions = lib.mapAttrsToList (name: value: {
              assertion = value.dataDir != null;
              message = "services.rclone-sync.${name}.dataDir must be a valid path";
            }) rcloneCfg;

            systemd.services = lib.mapAttrs' (
              name: remoteConfig:
              lib.nameValuePair "rclone-sync-${name}" {
                description = "Rclone sync for '${name}' from ${remoteConfig.dataDir}";
                wants = [ "network-online.target" ];
                after = [ "network-online.target" ];
                serviceConfig = {
                  Type = "oneshot";
                  LoadCredential = [ "rcloneConf:${remoteConfig.rcloneConfFile}" ];
                  EnvironmentFile = lib.optional (remoteConfig.environmentFile != null) remoteConfig.environmentFile;
                  # Security hardening
                  ReadOnlyPaths = [ remoteConfig.dataDir ]; # need to be able to read the backup dir
                  PrivateTmp = true;
                  ProtectSystem = "strict";
                  ProtectKernelTunables = true;
                  ProtectKernelModules = true;
                  ProtectControlGroups = true;
                  ProtectHome = "read-only";
                  PrivateDevices = true;
                  StateDirectory = "rclone-sync";
                  CacheDirectory = "rclone-sync";
                  CacheDirectoryMode = "0700";
                };

                script = ''
                  ${remoteConfig.package}/bin/rclone \
                    --config "$CREDENTIALS_DIRECTORY/rcloneConf" \
                    --cache-dir $CACHE_DIRECTORY \
                    --missing-on-dst - \
                    --error - \
                    sync "${remoteConfig.dataDir}" "$REMOTE" ${lib.escapeShellArgs remoteConfig.extraRcloneArgs}
                '';
              }
            ) (lib.filterAttrs (_n: v: v.enable) rcloneCfg);

            systemd.timers = lib.mapAttrs' (
              name: remoteConfig:
              lib.nameValuePair "rclone-sync-${name}" {
                wantedBy = [ "timers.target" ];
                inherit (remoteConfig) timerConfig;
              }
            ) (lib.filterAttrs (_n: v: v.enable && v.timerConfig != null) rcloneCfg);
          };

          desertflood.networking.services.rclone-sync = { };

        };

      };

  };

}
