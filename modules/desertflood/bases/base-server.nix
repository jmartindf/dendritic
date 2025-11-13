{
  config,
  inputs,
  lib,
  ...
}:
let
  flakeCfg = config;
  defaultUser = flakeCfg.desertflood.users.users.joe;
in
{
  flake.modules.nixos.base-server =
    { config, ... }:
    let
      nixOScfg = config;
    in
    {
      imports = [
        inputs.self.modules.nixos.smallstep
        inputs.self.modules.nixos.step-ssh
        inputs.self.modules.nixos.node_exporter
        inputs.self.modules.nixos.services
        inputs.self.modules.nixos.crowdsec
      ];

      desertflood.networking =
        let
          tsDomain = "${flakeCfg.desertflood.networking.tailscaleDomain}";
          defaultFQDN = "${nixOScfg.networking.hostName}.${nixOScfg.desertflood.networking.webDomain}";
        in
        {
          webDomain = lib.mkDefault tsDomain;
          webHost = lib.mkDefault defaultFQDN;
          tailscaleDomain = lib.mkDefault tsDomain;
          FQDN = lib.mkDefault defaultFQDN;
          tsFQDN = lib.mkDefault "${nixOScfg.networking.hostName}.${flakeCfg.desertflood.networking.tailscaleDomain}";
        };

      networking.firewall.allowPing = true;

      services = {
        tailscale.enable = true;
      };

      # every server should have a trusted `nixos` user that I can login to
      users.users.nixos = {
        isNormalUser = true;
        extraGroups = [ "wheel" ];
        openssh.authorizedKeys.keys = defaultUser.authorizedKeys;
      };
      nix.settings.trusted-users = [ "nixos" ];

      # symlink the Nix configuration, if it exists
      systemd.tmpfiles.rules = [
        "L? /etc/nixos/flake.nix  -  -  -  -  /home/nixos/dendritic/flake.nix"
      ];

    }; # end Nix OS module block
}
