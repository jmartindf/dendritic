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

          services = {
            tailscale.enable = true;
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

  flake.modules.nixos.base-server =
    { config, ... }:
    let
      nixOScfg = config;
    in
    {
      imports = [
        inputs.self.modules.nixos.alloy
        inputs.self.modules.nixos.crowdsec
        inputs.self.modules.nixos.services
        inputs.self.modules.nixos.smallstep
        inputs.self.modules.nixos.step-ssh
      ];

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

      # every server should have a trusted `nixos` user that I can login to
      users.users.nixos = {
        isNormalUser = true;
        extraGroups = [ "wheel" ];
        openssh.authorizedKeys.keys = defaultUser.authorizedKeys;
      };
      nix.settings.trusted-users = [ "nixos" ];

      services = {
        tailscale.enable = true;
      };

      # symlink the Nix configuration, if it exists
      systemd.tmpfiles.rules = [
        "L? /etc/nixos/flake.nix  -  -  -  -  /home/nixos/dendritic/flake.nix"
      ];

    }; # end Nix OS module block

}
