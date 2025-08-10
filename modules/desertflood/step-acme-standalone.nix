_: {
  flake.modules.nixos.step-acme-standalone =
    { config, ... }:
    let
      # p = pkgs.local;
      cfg = config;
    in
    {

      security = {

        acme = {
          acceptTerms = true;

          defaults = {
            listenHTTP = ":80";
            server = "https://pki.desertflood.link/acme/acme/directory";
            renewInterval = "*:0/20"; # every 20 minutes
            inherit (cfg.desertflood.defaultUser.emails.desertflood) email;
          };

        };

      };

    };

}
