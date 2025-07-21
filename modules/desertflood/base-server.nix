{ inputs, ... }:
{
  flake.modules.nixos.base-server = {
    imports = [
      inputs.self.modules.nixos.dockeras
      inputs.self.modules.nixos.step-ssh
    ];

    services = {
      tailscale.enable = true;

      prometheus.exporters = {
        node = {
          enable = true;
          enabledCollectors = [
            "systemd"
            "processes"
          ];
        };
      };
    };
  };
}
