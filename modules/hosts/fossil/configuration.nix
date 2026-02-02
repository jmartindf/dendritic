#  nix build .#.nixosConfigurations.fossil.config.system.build.isoImage
#  nix run github:nix-community/nixos-generators -- -f proxmox-lxc --system x86_64-linux --flake .#fossil
{
  config,
  inputs,
  ...
}:
let
  defaultUser = config.desertflood.users.users.joe;

  hostInfo = {
    hostName = "fossil";
    domain = "home.thosemartins.family";
    live = false;
    remote = false;
  };

  mTLS-required = false;
in
{
  flake.nixosConfigurations.fossil = inputs.self.lib.mk-os.linux "fossil";

  desertflood.hosts.hosts.fossil = hostInfo;

  flake.modules.nixos.fossil =
    { config, pkgs, ... }:
    let
      nixOScfg = config;
      svcConfig = nixOScfg.services;
      inherit (hostInfo) hostName;
      inherit (nixOScfg.desertflood.networking) webHost;
    in
    {
      imports = [
        inputs.self.modules.nixos.base
        inputs.self.modules.nixos.base-server
        inputs.self.modules.nixos.qemu-guest
      ];

      desertflood = {
        inherit defaultUser hostInfo;

        step-ca.certs.${hostName}.availableTo = { };

        services = {

          forgejo-runner.enable = true;

        };

      };

      networking = {
        inherit (hostInfo) hostName domain;
      };

      age.rekey.hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIKIqJzn5aPtpuRRe3Ywo3usTUP4H9oEHsKYK6k/xqo2D";

      users.users = {

        root = {
          openssh.authorizedKeys.keys = defaultUser.authorizedKeys;
        };
      };

    };
}
