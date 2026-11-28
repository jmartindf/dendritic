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
      { host, ... }:
      let
        inherit (host.desertflood) defaultUser;
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
    includes = [ df.cli.tools.docker ];
    homeManager = { }; # Maybe include certain Docker hubs / repositories?
  };
}
