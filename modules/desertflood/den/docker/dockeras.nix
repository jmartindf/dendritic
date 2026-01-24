{ df, ... }:
{
  den.aspects.dockeras.includes = [ df.dockeras ];

  df.dockeras =
    let
      username = "dockeras";
    in
    {
      description = "A user empowered to manage and control docker";

      includes = [
      ];

      nixos =
        { config, ... }:
        let
          inherit (config.desertflood) defaultUser;
        in
        {
          users.users.${username} = builtins.trace "evaluating users.users.${username}" {
            isNormalUser = true;
            extraGroups = [ "docker" ];
            openssh.authorizedKeys.keys = defaultUser.authorizedKeys;
          };
        };

      # homeManager = { };
    };

  flake.modules.nixos.dockeras =
    { config, ... }:
    let
      inherit (config.desertflood) defaultUser;
      username = "dockeras";
    in
    {
      users.users.${username} = builtins.trace "evaluating users.users.${username}" {
        isNormalUser = true;
        extraGroups = [ "docker" ];
        openssh.authorizedKeys.keys = defaultUser.authorizedKeys;
      };
    };

}
