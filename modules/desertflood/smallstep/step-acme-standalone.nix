{ config, ... }:
let
  flakeCfg = config;
in
{
  flake.modules.nixos.step-acme-standalone =
    { config, ... }:
    let
      cfg = config;
    in
    {

      security = {

        acme = {
          acceptTerms = true;

          defaults = {
            listenHTTP = ":80";
            server = "${flakeCfg.desertflood.step-ca.url}/acme/acme/directory";
            renewInterval = "*:0/20"; # every 20 minutes
            inherit (cfg.desertflood.defaultUser.emails.desertflood) email;
          };

        };

      };

    };

}
