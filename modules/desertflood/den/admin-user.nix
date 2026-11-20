_: {
  df.server = { host, ... }: {
    nixos =
      { config, ... }:
      let
        inherit (config.desertflood) defaultUser;
      in
      {
        users.users.${host.desertflood.globals.adminUsername} = {
          isNormalUser = true;
          extraGroups = [ "wheel" ];
          openssh.authorizedKeys.keys = defaultUser.authorizedKeys;
        };
        nix.settings.trusted-users = [ host.desertflood.globals.adminUsername ];
      };
  };
}
