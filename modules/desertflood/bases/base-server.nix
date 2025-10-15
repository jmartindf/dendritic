{
  config,
  inputs,
  lib,
  ...
}:
let
  flakeCfg = config;
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
        inputs.self.modules.nixos.redis
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
    }; # end Nix OS module block
}
