_: {
  df.server = { host, ... }: {
    nixos =
      { config, ... }:
      let
        inherit (config.desertflood) defaultUser;
      in
      {
        users.users.${host.globals.adminUsername} = {
          isNormalUser = true;
          extraGroups = [ "wheel" ];
          openssh.authorizedKeys.keys = defaultUser.authorizedKeys;
        };
        nix.settings.trusted-users = [ host.globals.adminUsername ];
      };
  };
}
