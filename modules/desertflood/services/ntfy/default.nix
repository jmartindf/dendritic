_: {

  config = {

    flake.modules.nixos.services =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      let
        nixOScfg = config;
      in
      {

        options = {
          desertflood.services.ntfy = {
            enable = lib.mkEnableOption "serving ntfy, a simple HTTP-based pub-sub notification service";
          };
        };

        config = lib.mkIf nixOScfg.desertflood.services.ntfy.enable {

          age.secrets.ntfy-sh-secrets = {
            rekeyFile = ./secrets.env.age;
            owner = "ntfy-sh";
            group = "ntfy-sh";
          };

          desertflood.networking.services.ntfy = { };

          services.ntfy-sh =
            let
              svcConfig = nixOScfg.desertflood.networking.services.ntfy;
            in
            {
              enable = true;

              package = pkgs.local.ntfy-sh;

              settings = {
                base-url = "${svcConfig.fullURL}";
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

  };

}
