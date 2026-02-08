#  nix build .#.nixosConfigurations.fossil.config.system.build.isoImage
#  nix run github:nix-community/nixos-generators -- -f proxmox-lxc --system x86_64-linux --flake .#fossil
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
    hostName = "fossil";
    domain = "home.thosemartins.family";
    live = false;
    remote = false;
    system = "x86_64-linux";
  };

  mTLS-required = false;
in
{
  desertflood.hosts.hosts.${hostInfo.hostName} = hostInfo;

  den.hosts.${hostInfo.system}.${hostInfo.hostName} = {
    description = "Nix OS homelab VM";
    capabilities.docker-server = true;
    users.nixos = { };
  };

  den.aspects = {

    ${hostInfo.hostName} = {
      includes = [
        df.base-server
        df.docker-server
      ];

      nixos =
        { config, pkgs, ... }:
        let
          nixOScfg = config;
          svcConfig = nixOScfg.services;
          inherit (hostInfo) hostName;
          inherit (nixOScfg.desertflood.networking) webHost;
        in
        {
          imports = [
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
    };
  };
}
