_: {

  flake.modules.nixos.step-ssh =
    { lib, pkgs, ... }:
    let
      p = pkgs.local;
    in
    {

      environment.systemPackages = [
        p."pki/signEm"
        p."pki/step"
      ];

      services = {

        openssh = {
          extraConfig = ''
            # Host certificate verification
            HostCertificate /etc/ssh/ssh_host_ed25519_key-cert.pub
            HostCertificate /etc/ssh/ssh_host_rsa_key-cert.pub
          '';
        };

      };

      security.pki.certificateFiles = [ pkgs.local."pki/rootCert" ];

      systemd = {
        services.renew-ssh-certificate = {
          name = "renew-ssh-certificate.service";
          description = "Weekly renewal for SSH host certificate";

          wants = [
            "network.target"
            "network-online.target"
          ];

          after = [
            "network.target"
            "network-online.target"
          ];

          serviceConfig = {
            Type = "oneshot";
            User = "root";
          };

          script = # bash
            ''
              if [[ -f "/etc/ssh/ssh_host_rsa_key-cert.pub" ]];
              then
                ${lib.getExe p."pki/step"} ssh renew "/etc/ssh/ssh_host_rsa_key-cert.pub" "/etc/ssh/ssh_host_rsa_key" --force 2> /dev/null
              fi
              if [[ -f "/etc/ssh/ssh_host_ed25519_key-cert.pub" ]];
              then
                ${lib.getExe p."pki/step"} ssh renew "/etc/ssh/ssh_host_ed25519_key-cert.pub" "/etc/ssh/ssh_host_ed25519_key" --force 2> /dev/null
              fi
              exit 0
            '';
        };

        timers.renew-ssh-certificate = {
          name = "renew-ssh-certificate.timer";
          description = "Weekly renewal for SSH host certificate";
          wantedBy = [ "timers.target" ];

          timerConfig = {
            # Run 5 minutes after system / systemd start
            OnStartupSec = "5min";

            # Run weekly
            OnCalendar = "weekly";

            # Delay the timer by a randomly selected, evenly distributed amount of time between
            # 0 seconds and 30 minutes
            RandomizedDelaySec = 1800;

            # Coalesce CPU wakeups
            AccuracySec = "1h";

            # store the time when the service unit was last triggered
            # When the timer is activated, trigger the service unit immediately
            # if it would have been triggered at least while inactive
            Persistent = true;
          };
        };
      };

    };

}
