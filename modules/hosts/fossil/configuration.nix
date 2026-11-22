#  nix build .#.nixosConfigurations.fossil.config.system.build.isoImage
#  nix run github:nix-community/nixos-generators -- -f proxmox-lxc --system x86_64-linux --flake .#fossil
{
  df,
  ...
}:
{
  den.hosts.fossil = {
    description = "Nix OS homelab VM";
    capabilities.server.docker = true;
    domain = "home.thosemartins.family";
    live = false;
    remote = false;
    system = "x86_64-linux";
  };

  den.aspects.fossil = {

    includes = [ df.machines.qemu-guest ];

    nixos =
      {
        host,
        ...
      }:
      {
        desertflood = {
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
}
