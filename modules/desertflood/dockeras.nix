_: {

  flake.modules.nixos.dockeras =
    {
      pkgs,
      ...
    }:
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
        openssh.authorizedKeys.keys = [
          "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILmB+dj98dHaQuaK0qcxTVpJxVAongswoUSZFOPrM4UW"
        ];
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
