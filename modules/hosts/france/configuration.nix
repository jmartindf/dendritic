#  nix build .#.nixosConfigurations.france.config.system.build.isoImage
{
  df,
  ...
}:
let
  mTLS-required = false;
in
{
  den.hosts.france = {
    description = "NixOS webapp host";
    capabilities.server.enable = true;
    domain = "df.fyi";
    live = true;
    remote = true;
    system = "x86_64-linux";
  };

  den.aspects.france = {

    includes = [
      df.machines.hetzner-cloud
      df.services.prometheus
      df.services.loki
      df.services.grafana
      df.services.traefik
      df.services.acme-dns
      df.services.apprise
      df.services.bluesky-pds
      df.services.forgejo
      df.services.lubelogger
      df.services.linkwarden
      df.services.attic
      df.services.koreader-sync
      df.services.webserv
      df.services.ntfy
    ];

    nixos =
      {
        host,
        pkgs,
        ...
      }:
      let
        inherit (host) hostName;
      in
      {
        imports = [
          { config.facter.reportPath = ./facter.json; }
        ];

        # Attach block storage volume, for Forgejo and others
        disko.devices.disk = {
          block = {
            device = "/dev/disk/by-id/scsi-0HC_Volume_103482293";
            type = "disk";
            content = {
              type = "filesystem";
              format = "ext4";
              mountpoint = "/var";
            };
          };
        };

        desertflood = {
          inherit (host.desertflood) defaultUser;

          networking = {
            services = {

              grafana = {
                domain = "desertflood.com";
                hostName = "monitor";
                path = "/grafana/";
              };

              prometheus = {
                domain = host.tsdomain;
                path = "/prometheus/";
              };

              ntfy = {
                domain = "desertflood.com";
                hostName = "ntfy";
                path = "";
              };

              apprise-api = {
                path = "";
              };

              forgejo = {
                domain = "desertflood.com";
                hostName = "git";
                path = "";
              };

              attic = {
                domain = "desertflood.com";
                hostName = "attic";
                path = "/";
              };

              lubelogger = {
                domain = "thosemartins.family";
                hostName = "lubelogger";
                path = "/";
              };

              bluesky-pds = {
                domain = "wordflood.net";
                hostName = "pds";
                path = "";
              };

              sftpgo = {
                domain = "df.fyi";
                path = "/sftpgo/";
              };

              linkwarden = {
                domain = "desertflood.com";
                hostName = "linkwarden";
                path = "/";
              };

              acme-dns = {
                domain = "desertflood.com";
                hostName = "auth";
                path = "";
              };

              koreader-sync = {
                domain = "desertflood.com";
                hostName = "kosync";
                path = "";
              };

            };

          };

          step-ca.certs.${hostName}.availableTo = { };

          services = {

            crowdsec.enable = false;

            apprise-api = {
              log-level = "INFO";
            };

            forgejo = {
              user = "git";
              mode = "prod";
            };

            prometheus = {
              inherit mTLS-required;
            };

            loki.loglevel = "warn";

            koreader-sync.disableRegistration = true;
          };
        };

        networking = {
          inherit (host) hostName domain;

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

        # Save port 22 for Endlessh?
        services.openssh.ports = [
          45897
          22
        ]; # from `uv run --with port4me python -m port4me --tool=ssh --user france`

        services.taskchampion-sync-server = {
          enable = true;
          package = pkgs.taskchampion-sync-server;
          allowClientIds = [ "5D51EACB-0887-4258-8D84-12B0239E280C" ];
        };

        # systemd.services.taskchampion-sync-server.environment = {
        #   RUST_LOG = "debug";
        # };

        age.rekey.hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKWvOZ3zQ5zitwbtU1iTa5FjG/47yGqGVoZ7jUg6ouku";
      };
  };

}
