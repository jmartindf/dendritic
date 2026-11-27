_: {
  df.step-acme = { host, ... }: {

    security.acme = {
      acceptTerms = true;

      defaults = {
        server = "${host.desertflood.step-ca.url}/acme/acme/directory";
        renewInterval = "*:0/20"; # every 20 minutes
        inherit (host.desertflood.defaultUser.emails.desertflood) email;
      };

    };

  };
}
