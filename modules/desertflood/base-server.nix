{ inputs, ... }:
{
  flake.modules.nixos.base-server =
    { ... }:
    {
      imports = [
        inputs.self.modules.nixos.dockeras
        inputs.self.modules.nixos.smallstep
        inputs.self.modules.nixos.step-ssh
        inputs.self.modules.nixos.node_exporter
      ];

      services = {
        tailscale.enable = true;
      };
    };
}
