_: {

  flake.modules.nixos.remote-builder = _: {

    nix.settings.trusted-users = [ "builder" ];

    users.users.builder = {
      isNormalUser = true;
    };

  };
}
