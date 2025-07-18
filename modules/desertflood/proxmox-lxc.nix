{ inputs, ... }:
{
  config = {

    flake.modules.nixos.proxmox-lxc =
      { modulesPath, ... }:
      {

        imports = [
          "${toString modulesPath}/virtualisation/proxmox-lxc.nix"
        ];

        boot.isContainer = true;

        # Suppress systemd units that don't work because of LXC
        systemd.suppressedSystemUnits = [
          "dev-mqueue.mount"
          "sys-kernel-debug.mount"
          "sys-fs-fuse-connections.mount"
        ];
      };

  };
}
