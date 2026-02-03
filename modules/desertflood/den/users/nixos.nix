{
  den,
  df,
  config,
  ...
}:
let
  flakeCfg = config;
  flakeModules = flakeCfg.flake.modules;
  dflib = flakeCfg.desertflood.lib;
in
{
  den.aspects.nixos.includes = [ df.nixos-user ];

  df.nixos-user =
    let
      username = "nixos";
    in
    den.lib.parametric {
      description = "A trusted admin user, instead of always using root";

      nixos =
        {
          config,
          ...
        }:
        let
          inherit (config.desertflood) defaultUser;
        in
        {
          users.users.${username} = builtins.traceVerbose "evaluating users.users.${username}" {
            isNormalUser = true;
            extraGroups = [ "wheel" ];
            openssh.authorizedKeys.keys = defaultUser.authorizedKeys;
          };
          nix.settings.trusted-users = [ username ];

        };

    };

}
