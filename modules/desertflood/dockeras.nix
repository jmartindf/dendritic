_: {

  flake.modules.nixos.dockeras =
    {
      config,
      pkgs,
      ...
    }:
    let
      inherit (config.desertflood) defaultUser;
    in
    {

      environment.systemPackages = [
        pkgs.docker-color-output
        pkgs.docker_28
        pkgs.lazydocker
        pkgs.local.vackup
      ];

      users.users.dockeras = {
        isNormalUser = true;
        extraGroups = [ "docker" ];
        openssh.authorizedKeys.keys = defaultUser.authorizedKeys;
      };

      virtualisation.docker = {
        enable = true;
        package = pkgs.docker_28;
        logDriver = "journald";
        storageDriver = "overlay2";
        enableOnBoot = true;
      };

    };
}
