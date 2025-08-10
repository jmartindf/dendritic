{ inputs, ... }:
{
  flake.modules.nixos.base-server =
    { pkgs, ... }:
    {
      imports = [
        inputs.self.modules.nixos.dockeras
        inputs.self.modules.nixos.step-ssh
      ];

      environment.systemPackages = [
        pkgs.local."pki/step"
      ];

      security.pki.certificateFiles = [ pkgs.local."pki/rootCert" ];

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
