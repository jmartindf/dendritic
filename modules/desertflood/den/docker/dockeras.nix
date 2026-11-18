{ df, ... }:
let
  username = "dockeras";
in
{
  den.schema.host.imports = [
    (
      { config, lib, ... }:
      {
        users = lib.mkIf config.capabilities.server.docker { ${username} = { }; };
      }
    )
  ];

  df.docker-server = {
    nixos =
      { config, ... }:
      let
        inherit (config.desertflood) defaultUser;
      in
      builtins.traceVerbose "implicit nixos module for configuring ${username} user" {
        users.users.${username} =
          builtins.traceVerbose "implicit module is evaluating users.users.${username}"
            {
              isNormalUser = true;
              extraGroups = [ "docker" ];
              openssh.authorizedKeys.keys = defaultUser.authorizedKeys;
            };
      };
  };

  # Every docker-server host gets the dockeras user, with Home Manager.
  den.aspects.${username}.includes = [
    df.${username}
  ];

  df.${username} = {
    description = "A user empowered to manage and control docker";

    homeManager = { };

    includes = builtins.traceVerbose "den.aspects.${username} active" [
      df.cli._.tools._.docker._.lazydocker # Useful tools such as lazydocker
    ];
  };
}
