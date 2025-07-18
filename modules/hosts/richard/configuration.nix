#  nix build .#.nixosConfigurations.richard.config.system.build.isoImage
#  nix run github:nix-community/nixos-generators -- -f proxmox-lxc --system x86_64-linux --flake .#richard
{ inputs, ... }:
let
  superego-key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAILmB+dj98dHaQuaK0qcxTVpJxVAongswoUSZFOPrM4UW";
in
{
  flake.modules.nixos.richard =
    {
      modulesPath,
      config,
      lib,
      ...
    }:
    {
      imports = [
        inputs.self.modules.nixos.base
        inputs.self.modules.nixos.proxmox-lxc
      ];

      nix.settings.trusted-users = [ "nixos" ];

      users.users = {

        nixos = {
          isNormalUser = true;
          extraGroups = [ "wheel" ];
          openssh.authorizedKeys.keys = [ superego-key ];
          uid = 1001;
        };

        root = {
          openssh.authorizedKeys.keys = [ superego-key ];
        };

      };
    };
}
