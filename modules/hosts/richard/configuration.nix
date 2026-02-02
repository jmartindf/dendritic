#  nix build .#.nixosConfigurations.richard.config.system.build.isoImage
#  nix run github:nix-community/nixos-generators -- -f proxmox-lxc --system x86_64-linux --flake .#richard
{
  den,
  df,
  config,
  inputs,
  ...
}:
let
  defaultUser = config.desertflood.users.users.joe;

  hostInfo = {
    hostName = "richard";
    domain = "home.thosemartins.family";
    live = false;
    remote = false;
  };

  flakeCfg = config;
in
{
  desertflood.hosts.hosts.richard = hostInfo;

  den.hosts.x86_64-linux.richard = {
    description = "Nix OS remote builder";
    users.nixos = { };
    users.dockeras = { };
  };

  den.aspects = {

    richard = {
      includes = [
        df.base
        df.base-server
        df.docker-server
      ];

      nixos =
        { ... }:
        {
          imports = builtins.trace "den.aspects.richard.nixos active" [
            inputs.self.modules.nixos.remote-builder
            inputs.self.modules.nixos.proxmox-lxc
          ];

          desertflood = {
            inherit defaultUser hostInfo;
            step-ca.certs.${hostInfo.hostName}.availableTo = { };
          };

          networking = {
            inherit (hostInfo) hostName domain;
          };
          age.rekey.hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKf0pQkV2GuvDHvX0OFyVKDDmizEbW5nfJJz7Xms2KYr";

          users.users = {

            root = {
              openssh.authorizedKeys.keys = defaultUser.authorizedKeys;
            };

            builder = {
              openssh.authorizedKeys.keys = [ flakeCfg.desertflood.builderKeys.builderKeys.psyche.publicKey ];
            };

          };

        };
    };

  };

}
