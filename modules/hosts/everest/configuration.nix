#  nix build .#.nixosConfigurations.everest.config.system.build.isoImage
{
  df,
  ...
}:
{
  den.hosts.everest = {
    description = "NixOS PKI and security host";
    capabilities.server.docker = true;
    domain = "df.fyi";
    live = true;
    remote = true;
    system = "x86_64-linux";
  };

  den.aspects.everest = {

    includes = [
      df.machines.hetzner-cloud
      df.services.step-ca
      df.services.traefik
      df.services.authentik
      df.services.smallstep
    ];

    nixos =
      {
        host,
        ...
      }:
      {
        imports = [
          { config.facter.reportPath = ./facter.json; }
        ];

        desertflood = {
          services = {

            step-ca = {
              # run ca-server
              enable = true;
              fqdns = [ "pki.desertflood.link" ];
            };

            traefik = {
              domain = host.tsFQDN;

              letsencrypt = {
                enable = true;
                tailscaleCerts = true;
                production = true;
                defaultResolver = "tailscale";
                acme-dns = true;
              };
            };

          };
        };

        networking = {
          enableIPv6 = true;

          interfaces.enp1s0.ipv6 = {

            addresses = [
              {
                address = "2a01:4ff:1f0:c8c::1";
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
        ]; # from `uv run --with port4me python -m port4me --tool=ssh --user everest`

        age.rekey.hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEuOqBBSAsZYRTXSZmT5InXA2XbI6ciRtESNcXHJxGij";
      };
  };

}
