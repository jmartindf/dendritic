#  nix build .#.nixosConfigurations.everest.config.system.build.isoImage
{
  config,
  inputs,
  ...
}:
let
  defaultUser = config.desertflood.users.users.joe;

  hostInfo = {
    hostName = "everest";
    domain = "df.fyi";
    live = true;
    remote = true;
  };

  mTLS-required = false;
in
{
  desertflood.hosts.hosts.everest = hostInfo;

  flake.modules.nixos.everest =
    { config, pkgs, ... }:
    let
      nixOScfg = config;
      svcConfig = nixOScfg.services;
      inherit (hostInfo) hostName;
      inherit (nixOScfg.desertflood.networking) webHost tailscaleDomain;
    in
    {
      imports = [
        inputs.self.modules.nixos.base
        inputs.self.modules.nixos.base-server
        inputs.self.modules.nixos.hetzner-cloud
        { config.facter.reportPath = ./facter.json; }
        inputs.self.modules.nixos.dockeras
      ];

      desertflood = {
        inherit defaultUser hostInfo;

        networking = {
          webDomain = "df.fyi";
        };

        step-ca.certs.${hostName}.availableTo = { };
      };

      networking = {
        inherit (hostInfo) hostName domain;

        enableIPv6 = true;

        interfaces.enp1s0.ipv6 = {

          addresses = [
            {
              address = "2a01:4ff:1f0:c8c::1/64";
              prefixLength = 64;
            }
          ];

          routes = [
            {
              address = "::";
              prefixLength = 0;
              via = "fe80::1";
            }
          ];

        };
      };

      # Save port 22 for Endlessh?
      services.openssh.ports = [
        45897
        22
      ]; # from `uv run --with port4me python -m port4me --tool=ssh --user everest`

      age.rekey.hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIEuOqBBSAsZYRTXSZmT5InXA2XbI6ciRtESNcXHJxGij";

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
