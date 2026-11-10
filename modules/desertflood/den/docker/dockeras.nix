{ df, ... }:
let
  username = "dockeras";

  osContext =
    { host }:
    {
      nixos =
        if host.capabilities.docker-server then
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
          }
        else
          builtins.traceVerbose "*not* nixos module for configuring ${username} user" { };

    };

  description = "A user empowered to manage and control docker";
in
{
  # Every docker-server host gets the dockeras user, with Home Manager.
  den.schema.host.imports = [
    (
      { config, lib, ... }:
      {
        users = lib.mkIf config.capabilities.docker-server { ${username} = { }; };
      }
    )
  ];

  den.aspects.${username} = {
    homeManager = { };
    includes = builtins.traceVerbose "den.aspects.${username} active" [
      df.cli._.tools._.docker._.lazydocker # Useful tools such as lazydocker
    ];
  };

  df.${username} = {
    inherit description;

    includes = [
      osContext
    ];
  };
}
