_: {
  den.aspects.france.nixos.desertflood.services.traefik = {
    domains = [
      {
        main = "desertflood.com";
        sans = [ "*.desertflood.com" ];
      }
      {
        main = "pds.wordflood.net";
        sans = [ "*.pds.wordflood.net" ];
      }
      {
        main = "thosemartins.family";
        sans = [ "*.thosemartins.family" ];
      }
      {
        main = "df.fyi";
        sans = [ "*.df.fyi" ];
      }
    ];

    letsencrypt = {
      enable = true;
      acme-dns = true;
      tailscaleCerts = true;
      production = true;
      defaultResolver = "dns-acme-dns";
    };
  };

}
