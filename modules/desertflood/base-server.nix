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
      ];

      desertflood.networking = {
        webDomain = lib.mkDefault "${flakeCfg.desertflood.networking.tailscaleDomain}";
        webHost = lib.mkDefault "${nixOScfg.networking.hostName}.${nixOScfg.desertflood.networking.webDomain}";
      };

      services = {
        tailscale.enable = true;
      };
    }; # end Nix OS module block
}
