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
        cacheCfg = svcsConfig.caddy.html-cache;
        caddyUser = svcsConfig.caddy.user;
        caddyGroup = svcsConfig.caddy.group;
      in
      {

        imports = [ ];

        options = {

          desertflood.services.caddy.html-cache = {

            enable = lib.mkEnableOption "caching static HTML files from B2 bucket";
            package = lib.mkPackageOption pkgs "rclone" { };

            settings = {

              remote = lib.mkOption {
                type = lib.types.str;
                description = "The remote to sync from";
                example = "myremote:bucket/path";
              };

              dataDir = lib.mkOption {
                type = lib.types.str;
                description = "The local directory to be copied to/from.";
                example = "/srv/restic";
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
            };
          };

        };

        config = lib.mkIf cacheCfg.enable {
          assertions = [
            {
              assertion = cacheCfg.settings.dataDir != null;
              message = "desertflood.services.caddy.html-cache.settings.dataDir must be a valid path";
            }
            {
              assertion = cacheCfg.settings.remote != null;
              message = "desertflood.services.caddy.html-cache.settings.remote must be configured";
            }
          ];

          systemd = {

            services.caddy-html-cache = {
              description = "Rclone sync for '${cacheCfg.settings.dataDir}' from ${cacheCfg.settings.remote}";
              wants = [ "network-online.target" ];
              after = [ "network-online.target" ];
              serviceConfig = {
                User = caddyUser;
                Group = caddyGroup;
                Type = "oneshot";
                LoadCredential = [ "rcloneConf:${cacheCfg.settings.rcloneConfFile}" ];
                # Security hardening
                ReadWritePaths = [ cacheCfg.settings.dataDir ]; # need to be able to write to the destination dir
                PrivateTmp = true;
                ProtectSystem = "strict";
                ProtectKernelTunables = true;
                ProtectKernelModules = true;
                ProtectControlGroups = true;
                ProtectHome = "read-only";
                PrivateDevices = true;
                StateDirectory = "caddy";
                CacheDirectory = "caddy";
                CacheDirectoryMode = "0700";
              };

              script = ''
                ${cacheCfg.package}/bin/rclone \
                  --config "$CREDENTIALS_DIRECTORY/rcloneConf" \
                  --cache-dir $CACHE_DIRECTORY \
                  --error - \
                  sync "${cacheCfg.settings.remote}" "${cacheCfg.settings.dataDir}" ${lib.escapeShellArgs cacheCfg.settings.extraRcloneArgs}
              '';
            };

            tmpfiles.rules = [
              "d ${cacheCfg.settings.dataDir} 0750 ${caddyUser} ${caddyGroup}"
              "L /var/lib/caddy/s3web  -  -  -  -  ${cacheCfg.settings.dataDir}"
            ];

            timers.caddy-html-cache = lib.mkIf (cacheCfg.enable && cacheCfg.settings.timerConfig != null) {
              wantedBy = [ "timers.target" ];
              inherit (cacheCfg.settings) timerConfig;
            };

            paths.caddy-html-cache = lib.mkIf cacheCfg.enable {
              description = "Trigger rclone sync for '${cacheCfg.settings.dataDir}' from ${cacheCfg.settings.remote} when trigger-rsync file is created.";
              pathConfig = {
                PathExists = "${cacheCfg.settings.dataDir}/trigger-rsync";
              };
            };
          };

        };
      };
  };
}
