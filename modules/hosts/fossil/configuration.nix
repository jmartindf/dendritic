#  nix build .#.nixosConfigurations.fossil.config.system.build.isoImage
#  nix run github:nix-community/nixos-generators -- -f proxmox-lxc --system x86_64-linux --flake .#fossil
{
  config,
  inputs,
  ...
}:
let
  defaultUser = config.desertflood.users.users.joe;

  hostInfo = {
    hostName = "fossil";
    domain = "home.thosemartins.family";
    live = false;
    remote = false;
  };

  flakeCfg = config;
  mTLS-required = false;
in
{
  desertflood = {
    inherit hostInfo defaultUser;

    hosts.hosts.fossil = hostInfo;
  };

  flake.modules.nixos.fossil =
    { config, ... }:
    let
      svcConfig = config.services;
      inherit (flakeCfg.desertflood.networking) webHost;
    in
    {
      imports = [
        inputs.self.modules.nixos.base
        inputs.self.modules.nixos.base-server
        inputs.self.modules.nixos.grafana
        inputs.self.modules.nixos.nginx
        inputs.self.modules.nixos.prometheus
        inputs.self.modules.nixos.step-acme-standalone
        inputs.self.modules.nixos.proxmox-lxc
      ];

      desertflood = {
        inherit defaultUser hostInfo;

        services.prometheus = {
          inherit mTLS-required;

          exporters.node.mTLS-required = mTLS-required;

          monitorHosts = [
            "everest.manticore-mark.ts.net"
            "firewalla.manticore-mark.ts.net"
            "hermes.manticore-mark.ts.net"
            "mark.manticore-mark.ts.net"
            "masto-es.manticore-mark.ts.net"
            "mastodon.manticore-mark.ts.net"
            "underworld.manticore-mark.ts.net"
          ];

          monitorHostsSecure = [
            "fossil.manticore-mark.ts.net"
            "richard.manticore-mark.ts.net"
          ];
        };
      };

      networking = {
        inherit (hostInfo) hostName domain;
      };

      age.rekey.hostPubkey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDJagbKOnqDYTIZSWnRnMXqSANNeK0KJ+fs6xMhJH6dW";

      nix.settings.trusted-users = [ "nixos" ];

      users.users = {

        nixos = {
          isNormalUser = true;
          extraGroups = [ "wheel" ];
          openssh.authorizedKeys.keys = defaultUser.authorizedKeys;
        };

        root = {
          openssh.authorizedKeys.keys = defaultUser.authorizedKeys;
        };

      };

      services.nginx.virtualHosts.${webHost} = {
        addSSL = true;
        enableACME = true;

        locations."/prometheus/" = {
          proxyPass = "https://${toString svcConfig.prometheus.listenAddress}:${toString svcConfig.prometheus.port}";
          proxyWebsockets = true;
          recommendedProxySettings = true;
        };

        locations."/grafana/" = {
          proxyPass = "http://${toString svcConfig.grafana.settings.server.http_addr}:${toString svcConfig.grafana.settings.server.http_port}";
          proxyWebsockets = true;
          recommendedProxySettings = true;
        };
      };

    };
}
