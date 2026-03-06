{
  config,
  inputs,
  lib,
  ...
}:
let
  flakeCfg = config;
  defaultUser = flakeCfg.desertflood.users.users.joe;
in
{
  df.base-server = {
    description = "Common to all headless servers";

    nixos =
      {
        config,
        lib,
        ...
      }:
      let
        nixOScfg = config;
      in
      {
        imports = builtins.traceVerbose "df.base-server.nixos active" [
          inputs.self.modules.nixos.alloy
          inputs.self.modules.nixos.crowdsec
          inputs.self.modules.nixos.services
          inputs.self.modules.nixos.smallstep
          inputs.self.modules.nixos.step-ssh
        ];

        config = {
          desertflood.services.prometheus.alloy.enable = true;

          desertflood.networking =
            let
              tsDomain = "${flakeCfg.desertflood.networking.tailscaleDomain}";
              defaultFQDN = "${nixOScfg.networking.hostName}.${nixOScfg.desertflood.networking.webDomain}";
            in
            {
              webDomain = lib.mkDefault tsDomain;
              webHost = lib.mkDefault defaultFQDN;
              tailscaleDomain = lib.mkDefault tsDomain;
              FQDN = lib.mkDefault defaultFQDN;
              tsFQDN = lib.mkDefault "${nixOScfg.networking.hostName}.${flakeCfg.desertflood.networking.tailscaleDomain}";
            };

          networking.firewall.allowPing = true;

          # Remote terminal application that allows roaming, supports intermittent
          # connectivity, and provides intelligent local echo and line editing of user keystrokes.
          programs.mosh.enable = true;

          services = {
            tailscale.enable = true;
            tailscale.extraSetFlags = [ "--accept-routes" ];
          };

          # symlink the Nix configuration, if it exists
          systemd.tmpfiles.rules = [
            "L? /etc/nixos/flake.nix  -  -  -  -  /home/nixos/dendritic/flake.nix"
          ];
        };
      };

    darwin =
      {
        ...
      }:
      {
        imports = [
        ];

        config = {
        };
      };

    homeManager =
      {
        ...
      }:
      {
        imports = [
        ];

        config = {
        };
      };

  };
}
