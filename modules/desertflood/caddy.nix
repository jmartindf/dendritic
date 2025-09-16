{ lib, ... }:
{
  flake.modules.nixos.nixos =
    { config, pkgs, ... }:
    let
      caddyWithPlugins = pkgs.caddy.withPlugins {
        plugins = [
          "github.com/greenpau/caddy-security@v1.1.31"
          "github.com/darkweak/souin/plugins/caddy@v1.7.7"
          "github.com/darkweak/storages/simplefs/caddy@v0.0.16"
          "github.com/darkweak/storages/nuts/caddy@v0.0.16"
          "github.com/lucaslorentz/caddy-docker-proxy/v2@v2.10.0"
          "github.com/abiosoft/caddy-json-schema@v0.0.0-20220621031927-c4d6e132f3af"
        ];
        hash = "sha256-FCEetoP0eg9ybaFagrTSaawzftdvnKeSC+oIG3Abr0Q=";
      };

      configFile =
        let
          Caddyfile =
            pkgs.writeTextDir "Caddyfile" # caddy
              ''
                {
                  ${config.desertflood.services.caddy.settings.global}
                }

                ${config.desertflood.services.caddy.settings.caddyfile}
              '';

          Caddyfile-formatted = pkgs.runCommand "Caddyfile-formatted" { } ''
            mkdir -p $out
            cp --no-preserve=mode ${Caddyfile}/Caddyfile $out/Caddyfile
            ${caddyWithPlugins}/bin/caddy fmt --overwrite $out/Caddyfile
          '';
        in
        "${
          if pkgs.stdenv.buildPlatform == pkgs.stdenv.hostPlatform then Caddyfile-formatted else Caddyfile
        }/Caddyfile";

    in
    {
      imports = [ ];

      options.desertflood = {

        services.caddy = {
          enable = lib.mkEnableOption "customized Caddy application server";

          settings = {

            global = lib.mkOption {
              type = lib.types.lines;
              default = # caddy
                ''
                  admin unix//run/caddy/caddy-admin.sock
                '';
              example = # caddy
                ''
                  local_certs
                '';
              description = "Global configuration options for Caddy";
            };

            caddyfile = lib.mkOption {
              type = lib.types.lines;
              default = "";
              description = "The rest of the Caddyfile configuration";
            };

          };
        };

      };

      config = lib.mkIf config.desertflood.services.caddy.enable {

        desertflood.services.caddy.settings.global = # caddy
          ''
            admin unix//run/caddy/caddy-admin.sock
          '';

        # https://github.com/quic-go/quic-go/wiki/UDP-Buffer-Sizes
        boot.kernel.sysctl."net.core.rmem_max" = lib.mkDefault 2500000;
        boot.kernel.sysctl."net.core.wmem_max" = lib.mkDefault 2500000;

        environment = {

          systemPackages = [ caddyWithPlugins ];
          etc."caddy/Caddyfile".source = configFile;

        };

        users.users.caddy = {
          createHome = true;
          description = "Caddy web server";
          group = "caddy";
          home = "/var/lib/caddy";
          isSystemUser = true;
          shell = null;
          uid = config.ids.uids.caddy;
        };

        users.groups.caddy = {
          gid = config.ids.gids.caddy;
        };

        services = {
          tailscale.permitCertUid = "caddy";
        };

        systemd.services.caddy = {

          description = "Caddy";
          documentation = [ "https://caddyserver.com/docs/" ];

          wantedBy = [ "multi-user.target" ];

          after = [
            "network.target"
          ];
          requires = [ "network.target" ];

          startLimitIntervalSec = 14400;
          startLimitBurst = 10;

          reloadTriggers = [ configFile ];

          serviceConfig = {
            User = "caddy";
            Group = "caddy";
            Type = "notify";

            ReadWritePaths = "/var/lib/caddy";
            StateDirectory = "caddy";
            LogsDirectory = "caddy";
            RuntimeDirectory = "caddy";
            ConfigurationDirectory = "caddy";

            ExecStart = lib.concatStringsSep " " [
              "${caddyWithPlugins}/bin/caddy"
              "run"
              "--environ"
              "--config"
              "/etc/caddy/Caddyfile"
            ];

            ExecReload = lib.concatStringsSep " " [
              "${caddyWithPlugins}/bin/caddy"
              "reload"
              "--config"
              "/etc/caddy/Caddyfile"
              "--force"
            ];

            Restart = "on-failure";
            RestartPreventExitStatus = 1;
            RestartSec = "5s";

            TimeoutStopSec = "5s";

            LimitNOFILE = 1048576;

            PrivateTmp = true;

            ProtectSystem = "full";
            ProtectHome = true;

            AmbientCapabilities = [
              "CAP_NET_ADMIN"
              "CAP_NET_BIND_SERVICE"
            ];
          };

        };

      };
    };
}
