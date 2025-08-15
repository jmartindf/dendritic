{ config, ... }:
let
  flakeCfg = config;
in
{
  flake.modules.nixos.step-acme = _: {

    security.acme = {
      acceptTerms = true;

      defaults = {
        server = "${flakeCfg.desertflood.step-ca.url}/acme/acme/directory";
        renewInterval = "*:0/20"; # every 20 minutes
        inherit (flakeCfg.desertflood.defaultUser.emails.desertflood) email;
      };

    };

  };
}
