_: {

  config = {

    flake.modules.nixos.lubelogger =
      {
        config,
        lib,
        pkgs,
        ...
      }:
      let
        nixOScfg = config;
        llCfg = nixOScfg.services.lubelogger;
        svcsCfg = nixOScfg.desertflood.services;
        llNetCfg = nixOScfg.desertflood.networking.services.lubelogger;
      in
      {

        # Pending [PR 371458](https://github.com/NixOS/nixpkgs/pull/371458)
        # Original: https://github.com/bct/nixpkgs/blob/6fc07697e3fae972e865241a73cec8657a984164/nixos/modules/services/web-apps/lubelogger.nix
        imports = [ ./_lubelogger.nix ];

        options = {

          desertflood.services.lubelogger = {
            enable = lib.mkEnableOption "LubeLogger, a self-hosted, open-source, web-based vehicle maintenance and fuel mileage tracker";

            port = lib.mkOption {
              type = lib.types.port;
              description = "The TCP port LubeLogger will listen on.";
            };
          };

        };

        config = lib.mkIf svcsCfg.lubelogger.enable {

          age.secrets.lubelogger-env = {
            rekeyFile = ./lubelogger-secrets.env.age;
            owner = llCfg.user;
            inherit (llCfg) group;
          };

          desertflood = {
            networking.services.lubelogger = { };

            services = {
              lubelogger.port = llCfg.port;
              postgresql.enable = true;
            };
          };

          services.postgresql = {
            ensureDatabases = [ llCfg.user ];
            ensureUsers = [
              {
                name = llCfg.user;
                ensureDBOwnership = true;
              }
            ];
          };

          services.lubelogger = {
            enable = true;
            # Pending [PR 453649](https://github.com/NixOS/nixpkgs/pull/453649)
            package = pkgs.local.lubelogger;

            environmentFile = nixOScfg.age.secrets.lubelogger-env.path;

            settings = {
              LC_ALL = "en_US.UTF-8";
              LANG = "en_US.UTF-8";
              POSTGRES_CONNECTION = "Host=/run/postgresql;Port=5432;Username=${llCfg.user};Database=${llCfg.user};";
              EnableAuth = "true";
              DefaultReminderEmail = "joe@desertflood.com";
              EnableRootUserOIDC = "false";
              LUBELOGGER_OPEN_REGISTRATION = "false";
              LUBELOGGER_DOMAIN = "${llNetCfg.fullURL}"; # - URL to Instance of LubeLogger used to generate email links
              MailConfig__EmailFrom = "admin@thosemartins.family";
              MailConfig__Port = "587";
              OpenIDConfig__Name = "authentik Desertflood";
              OpenIDConfig__ClientId = "BcWXIRxmmYyUfKbTOb871Eq2gYv05Ify3GQ7hgie";
              OpenIDConfig__AuthURL = "https://sso.desertflood.link/application/o/authorize/";
              OpenIDConfig__TokenURL = "https://sso.desertflood.link/application/o/token/";
              OpenIDConfig__UserInfoURL = "https://sso.desertflood.link/application/o/userinfo/";
              OpenIDConfig__LogOutURL = "https://sso.desertflood.link/application/o/lube-logger/end-session/";
              OpenIDConfig__RedirectURL = "https://${llNetCfg.fqdn}/Login/RemoteAuth";
              OpenIDConfig__Scope = "openid email";
              OpenIDConfig__ValidateState = "false";
              OpenIDConfig__UsePKCE = "true";
              OpenIDConfig__DisableRegularLogin = "true";
            };
          };

        };

      };

  };

}
