#  nix build .#.nixosConfigurations.france.config.system.build.isoImage
{
  config,
  inputs,
  ...
}:
let
  defaultUser = config.desertflood.users.users.joe;

  hostInfo = {
    hostName = "france";
    domain = "df.fyi";
    live = false;
    remote = true;
  };

  mTLS-required = false;
in
{
  desertflood.hosts.hosts.france = hostInfo;

  flake.modules.nixos.france =
    { config, ... }:
    let
      nixOScfg = config;
      svcConfig = nixOScfg.services;
      inherit (hostInfo) hostName;
      inherit (nixOScfg.desertflood.networking) webHost;
    in
    {
      imports = [
        inputs.self.modules.nixos.base
        inputs.self.modules.nixos.base-server
        inputs.self.modules.nixos.nginx
        inputs.self.modules.nixos.letsencrypt
        inputs.self.modules.nixos.hetzner-cloud
        { config.facter.reportPath = ./facter.json; }
      ];

      desertflood = {
        inherit defaultUser hostInfo;

        networking.webDomain = "df.fyi";

        step-ca.certs.${hostName}.availableTo = { };

        #   services.prometheus = {
        #     inherit mTLS-required;
        #
        #     exporters.node.mTLS-required = mTLS-required;
        #
        #     monitorHosts = [
        #       "everest.manticore-mark.ts.net"
        #       "firewalla.manticore-mark.ts.net"
        #       "hermes.manticore-mark.ts.net"
        #       "mark.manticore-mark.ts.net"
        #       "masto-es.manticore-mark.ts.net"
        #       "mastodon.manticore-mark.ts.net"
        #       "underworld.manticore-mark.ts.net"
        #     ];
        #
        #     monitorHostsSecure = [
        #       "127.0.0.1"
        #       "richard.manticore-mark.ts.net"
        #     ];
        #   };
      };

      networking = {
        inherit (hostInfo) hostName domain;

        enableIPv6 = true;

        interfaces.enp1s0.ipv6 = {

          addresses = [
            {
              address = "2a01:4ff:1f0:a0b3::1";
              prefixLength = 64;
            }
          ];

          routes = [
            {
              address = "::";
              prefixLength = 0;
              via = "fe80::1";
            }
          ];

        };
      };

      services.taskchampion-sync-server = {
        enable = true;
        allowClientIds = [ "5D51EACB-0887-4258-8D84-12B0239E280C" ];
      };

      age.rekey.hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKWvOZ3zQ5zitwbtU1iTa5FjG/47yGqGVoZ7jUg6ouku";

      nix.settings.trusted-users = [ "nixos" ];

      users.users = {

        nixos = {
          isNormalUser = true;
          extraGroups = [ "wheel" ];
          openssh.authorizedKeys.keys = defaultUser.authorizedKeys;
        };

        root = {
          openssh.authorizedKeys.keys = defaultUser.authorizedKeys;
        };

      };

      services.nginx = {

        virtualHosts.taskchamp = {
          serverName = "taskchamp.desertflood.com";
          forceSSL = true;
          enableACME = true;
          locations."/" = {
            proxyPass = "http://${toString svcConfig.taskchampion-sync-server.host}:${toString svcConfig.taskchampion-sync-server.port}";
            recommendedProxySettings = true;
          };
        };

        virtualHosts.${webHost} = {
          addSSL = true;
          enableACME = true;

          locations = {
            #   "/prometheus/" = {
            #     proxyPass = "https://${toString svcConfig.prometheus.listenAddress}:${toString svcConfig.prometheus.port}";
            #     proxyWebsockets = true;
            #     recommendedProxySettings = true;
            #   };
            #
            #   "/grafana/" = {
            #     proxyPass = "http://${toString svcConfig.grafana.settings.server.http_addr}:${toString svcConfig.grafana.settings.server.http_port}";
            #     proxyWebsockets = true;
            #     recommendedProxySettings = true;
            #   };
            #
            #   "/forgejo/" = {
            #     proxyPass = "http://${toString svcConfig.forgejo.settings.server.HTTP_ADDR}:${toString svcConfig.forgejo.settings.server.HTTP_PORT}/";
            #     proxyWebsockets = true;
            #     recommendedProxySettings = true;
            #     extraConfig = # nginx
            #       ''
            #         client_max_body_size 1G;
            #       '';
            #   };
          };

        };
      };

    };
}
