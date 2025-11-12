#  nix build .#.nixosConfigurations.richard.config.system.build.isoImage
#  nix run github:nix-community/nixos-generators -- -f proxmox-lxc --system x86_64-linux --flake .#richard
{
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
  mTLS-required = false;
in
{
  desertflood.hosts.hosts.richard = hostInfo;

  flake.modules.nixos.richard =
    { ... }:
    {
      imports = [
        inputs.self.modules.nixos.base
        inputs.self.modules.nixos.base-server
        inputs.self.modules.nixos.dockeras
        inputs.self.modules.nixos.remote-builder
        inputs.self.modules.nixos.proxmox-lxc
      ];

      desertflood = {
        inherit defaultUser hostInfo;
        services.prometheus.exporters.node.mTLS-required = mTLS-required;
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
}
