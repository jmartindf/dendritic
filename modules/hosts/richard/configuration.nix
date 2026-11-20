#  nix build .#.nixosConfigurations.richard.config.system.build.isoImage
#  nix run github:nix-community/nixos-generators -- -f proxmox-lxc --system x86_64-linux --flake .#richard
{
  df,
  ...
}:
let
  hostInfo = {
    hostName = "richard";
    domain = "home.thosemartins.family";
    live = false;
    remote = false;
    system = "x86_64-linux";
  };
in
{
  desertflood.hosts.hosts.${hostInfo.hostName} = hostInfo;

  den.hosts.${hostInfo.system}.${hostInfo.hostName} = {
    description = "Nix OS remote builder";
    capabilities.server.docker = true;
  };

  den.aspects.${hostInfo.hostName} = {

    includes = [
      df.remote-builder
      df.machines.proxmox-lxc
    ];

    builder-clients = { host, ... }: {
      key = host.desertflood.builderKeys.builderKeys.psyche.publicKey;
    };

    nixos =
      { host, ... }:
      let
        defaultUser = host.desertflood.users.users.joe;
      in
      {
        imports = builtins.traceVerbose "den.aspects.richard.nixos active" [
        ];

        desertflood = {
          inherit defaultUser hostInfo;
          step-ca.certs.${hostInfo.hostName}.availableTo = { };
        };

        networking = {
          inherit (hostInfo) hostName domain;
        };
        age.rekey.hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKf0pQkV2GuvDHvX0OFyVKDDmizEbW5nfJJz7Xms2KYr";

        users.users.root.openssh.authorizedKeys.keys = defaultUser.authorizedKeys;
      };
  };

}
