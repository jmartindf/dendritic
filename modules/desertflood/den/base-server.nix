{
  df,
  lib,
  ...
}:
{
  den.schema.conf = {
    options.capabilities.server.enable = lib.mkEnableOption "Is host a server of any kind?";
  };

  den.schema.host.imports = [
    (
      { config, lib, ... }:
      {
        # Every server host gets the admin user
        users = lib.mkIf config.capabilities.server.enable {
          ${config.desertflood.globals.adminAspect} = {
            userName = config.desertflood.globals.adminUsername;
          };
        };

        # Every server host automatically includes the server aspect
        includes = lib.mkIf config.capabilities.server.enable [
          df.server
        ];
      }
    )
  ];

  df.server = {
    description = "Common to all headless servers";

    includes = [
      df.services.alloy
      # df.services.crowdsec # Disable until I've fixed it
      df.services.smallstep
      df.services.step-ssh
      df.shared-secrets
    ];

    nixos =
      { host, ... }:
      {
        config = builtins.traceVerbose "df.server.nixos active" {

          users.users.root.openssh.authorizedKeys.keys = host.desertflood.defaultUser.authorizedKeys;

          desertflood.step-ca.certs.${host.hostName}.availableTo = { };

          networking = {
            inherit (host) hostName domain;
            firewall.allowPing = true;
          };

          # Remote terminal application that allows roaming, supports intermittent
          # connectivity, and provides intelligent local echo and line editing of user keystrokes.
          programs.mosh.enable = true;

          services = {
            tailscale.enable = true;
            tailscale.extraSetFlags = [ "--accept-routes" ];

            # Limit journaling
            journald.extraConfig = ''
              MaxRetentionSec=1month
              MaxFileSec=1week
              SystemMaxUse=500M
              SystemMaxFiles=5
              RuntimeMaxUse=100M
              RuntimeMaxFiles=5
            '';
          };

          # symlink the Nix configuration, if it exists
          systemd.tmpfiles.rules = [
            "L? /etc/nixos/flake.nix  -  -  -  -  /home/${host.desertflood.globals.adminUsername}/dendritic/flake.nix"
          ];
        };
      };

    darwin =
      {
        ...
      }:
      {
        imports = [
        ];

        config = {
        };
      };

    homeManager =
      {
        ...
      }:
      {
        imports = [
        ];

        config = {
        };
      };

  };
}
