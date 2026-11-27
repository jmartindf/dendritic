#  nix build .#.nixosConfigurations.richard.config.system.build.isoImage
#  nix run github:nix-community/nixos-generators -- -f proxmox-lxc --system x86_64-linux --flake .#richard
{
  df,
  ...
}:
{
  den.hosts.richard = {
    description = "Nix OS remote builder";
    capabilities.server.docker = true;
    system = "x86_64-linux";
    domain = "home.thosemartins.family";
    live = true;
    remote = false;
  };

  den.aspects.richard = {

    includes = [
      df.remote-builder
      df.machines.proxmox-lxc
    ];

    builder-clients = { host, ... }: {
      key = host.desertflood.builderKeys.builderKeys.psyche.publicKey;
    };

    nixos.age.rekey.hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKf0pQkV2GuvDHvX0OFyVKDDmizEbW5nfJJz7Xms2KYr";

  };

}
