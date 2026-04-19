{ den, df, ... }:
let
  username = "dockeras";

  homeManager =
    { HM-OS-HOST }:
    let
      inherit (HM-OS-HOST) OS host;
      hmClass = "homeManager";

      hmUserModule =
        let
          HM = den.aspects.${username};

          user = {
            aspect = username;
            class = hmClass;
            name = username;
            userName = username;
          };

          aspect = HM {
            HM-OS-USER = {
              inherit
                OS
                HM
                host
                user
                ;
            };
          };

          module = aspect.resolve { class = hmClass; };
        in
        module;

      aspect.${host.class} =
        if host.capabilities.docker-server then
          {
            home-manager.users.${username} = {
              imports = [
                hmUserModule
              ];
            };
          }
        else
          { };
    in
    aspect;

  osContext =
    { OS, host }:
    {
      nixos =
        if host.capabilities.docker-server then
          { config, ... }:
          let
            inherit (config.desertflood) defaultUser;
          in
          builtins.traceVerbose "nixos module for configuring ${username} user" {
            users.users.${username} = {
              isNormalUser = true;
              extraGroups = [ "docker" ];
              openssh.authorizedKeys.keys = defaultUser.authorizedKeys;
            };
          }
        else
          builtins.traceVerbose "*not* nixos module for configuring ${username} user" { };

    };

  description = "A user empowered to manage and control docker";
in
{
  den.aspects.${username} = den.lib.parametric.atLeast {
    homeManager = { };
    includes = builtins.traceVerbose "den.aspects.${username} active" [
      den.default
      df.cli._.tools._.docker # Useful tools such as lazydocker
    ];
  };

  df.${username} = den.lib.parametric {
    inherit description;

    includes = [
      (den.lib.take.exactly osContext)
      (den.lib.take.exactly homeManager)
    ];
  };

  flake.modules.nixos.${username} =
    { config, ... }:
    let
      inherit (config.desertflood) defaultUser;
      inherit username;
    in
    {
      users.users.${username} = builtins.traceVerbose "evaluating users.users.${username}" {
        isNormalUser = true;
        extraGroups = [ "docker" ];
        openssh.authorizedKeys.keys = defaultUser.authorizedKeys;
      };
    };

}
