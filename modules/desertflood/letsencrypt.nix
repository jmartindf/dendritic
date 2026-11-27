_: {
  df.services.letsencrypt = { host, ... }: {
    nixos.security.acme = {
      acceptTerms = true;
      defaults.email = host.desertflood.defaultUser.emails.desertflood.email;
    };
  };
}
