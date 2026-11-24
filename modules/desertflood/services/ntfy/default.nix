_: {

  df.services.ntfy =
    let
      ntfyHost = "ntfy.desertflood.com";
    in
    {

      traefik-apps = { config, ... }: {
        ntfy = {
          rule = "Host(`${ntfyHost}`)";
          url = "http://${toString config.services.ntfy-sh.settings.listen-http}";
          middlewares = "chain-no-auth@file";
        };
      };

      nixos =
        {
          config,
          pkgs,
          ...
        }:
        let
          nixOScfg = config;
        in
        {

          age.secrets.ntfy-sh-secrets = {
            rekeyFile = ./secrets.env.age;
            owner = "ntfy-sh";
            group = "ntfy-sh";
          };

          services.ntfy-sh = {
            enable = true;

            package = pkgs.ntfy-sh;

            settings = {
              base-url = "https://${ntfyHost}";
              behind-proxy = true;
              auth-default-access = "deny-all";
              upstream-base-url = "https://ntfy.sh";
            };
          };

          systemd.services.ntfy-sh = {
            serviceConfig.EnvironmentFile = nixOScfg.age.secrets.ntfy-sh-secrets.path;
          };

        };
    };
}
