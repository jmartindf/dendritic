#  nix build .#.nixosConfigurations.richard.config.system.build.isoImage
#  nix run github:nix-community/nixos-generators -- -f proxmox-lxc --system x86_64-linux --flake .#richard
{
  config,
  inputs,
  ...
}:
let
  defaultUser = config.desertflood.users.users.joe;
  hostInfo = config.desertflood.hosts.hosts.richard;
in
{
  flake.modules.nixos.richard = {
    imports = [
      inputs.self.modules.nixos.base
      inputs.self.modules.nixos.base-server
      inputs.self.modules.nixos.remote-builder
      inputs.self.modules.nixos.proxmox-lxc
    ];

    desertflood.defaultUser = defaultUser;
    desertflood.hostInfo = hostInfo;

    networking = {
      inherit (hostInfo) hostName domain;
    };
    age.rekey.hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKf0pQkV2GuvDHvX0OFyVKDDmizEbW5nfJJz7Xms2KYr";

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

      builder = {
        openssh.authorizedKeys.keys = [ config.desertflood.builderKeys.builderKeys.psyche.publicKey ];
      };

    };
  };
}
