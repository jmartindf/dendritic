#  nix build .#.nixosConfigurations.fossil.config.system.build.isoImage
#  nix run github:nix-community/nixos-generators -- -f proxmox-lxc --system x86_64-linux --flake .#fossil
{
  df,
  ...
}:
let
  hostInfo = {
    hostName = "fossil";
    domain = "home.thosemartins.family";
    live = false;
    remote = false;
    system = "x86_64-linux";
  };
in
{
  desertflood.hosts.hosts.${hostInfo.hostName} = hostInfo;

  den.hosts.${hostInfo.system}.${hostInfo.hostName} = {
    description = "Nix OS homelab VM";
    capabilities.server.docker = true;
    inherit (hostInfo) domain live remote;
  };

  den.aspects = {

    ${hostInfo.hostName} = {

      includes = [ df.machines.qemu-guest ];

      nixos =
        {
          host,
          ...
        }:
        {
          desertflood = {
            inherit hostInfo;
            inherit (host.desertflood) defaultUser;

            step-ca.certs.${host.hostName}.availableTo = { };

            services = {

              forgejo-runner.enable = true;

            };

          };

          networking = {
            inherit (host) hostName domain;
          };

          age.rekey.hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKIqJzn5aPtpuRRe3Ywo3usTUP4H9oEHsKYK6k/xqo2D";
        };
    };
  };
}
