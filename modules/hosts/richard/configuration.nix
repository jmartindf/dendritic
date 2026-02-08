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
    system = "x86_64-linux";
  };

  flakeCfg = config;
in
{
  desertflood.hosts.hosts.${hostInfo.hostName} = hostInfo;

  den.hosts.${hostInfo.system}.${hostInfo.hostName} = {
    description = "Nix OS remote builder";
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
        { ... }:
        {
          imports = builtins.traceVerbose "den.aspects.richard.nixos active" [
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
