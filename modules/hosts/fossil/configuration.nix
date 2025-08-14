#  nix build .#.nixosConfigurations.fossil.config.system.build.isoImage
#  nix run github:nix-community/nixos-generators -- -f proxmox-lxc --system x86_64-linux --flake .#fossil
{
  config,
  inputs,
  ...
}:
let
  defaultUser = config.desertflood.users.users.joe;
  hostInfo = config.desertflood.hosts.hosts.fossil;
  flakeCfg = config;
  mTLS-required = false;
in
{
  flake.modules.nixos.fossil =
    { config, ... }:
    {
      imports = [
        inputs.self.modules.nixos.base
        inputs.self.modules.nixos.base-server
        inputs.self.modules.nixos.proxmox-lxc
      ];

      desertflood = {
        inherit defaultUser hostInfo;
        services.prometheus.exporters.node.mTLS-required = mTLS-required;
      };

      networking = {
        inherit (hostInfo) hostName domain;
      };

      age.rekey.hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDJagbKOnqDYTIZSWnRnMXqSANNeK0KJ+fs6xMhJH6dW";

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
    };
}
