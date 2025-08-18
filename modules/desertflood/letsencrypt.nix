{ config, ... }:
let
  flakeCfg = config;
in
{
  flake.modules.nixos.letsencrypt = _: {

    security.acme = {
      acceptTerms = true;
      defaults.email = flakeCfg.desertflood.defaultUser.emails.desertflood.email;
    };

  };
}
