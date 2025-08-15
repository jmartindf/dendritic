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
  desertflood.networking = {
    webDomain = lib.mkDefault "${flakeCfg.desertflood.networking.tailscaleDomain}";
    webHost = lib.mkDefault "${flakeCfg.desertflood.hostInfo.hostName}.${flakeCfg.desertflood.networking.webDomain}";
  };

  flake.modules.nixos.base-server =
    { ... }:
    {
      imports = [
        inputs.self.modules.nixos.smallstep
        inputs.self.modules.nixos.step-ssh
        inputs.self.modules.nixos.node_exporter
      ];

      services = {
        tailscale.enable = true;
      };
    }; # end Nix OS module block
}
