# SPDX-FileCopyrightText: 2025 Joe Martin <joe@desertflood.com>
# SPDX-License-Identifier: BlueOak-1.0.0
_: {

  df.services.forgejo-runner.nixos =
    {
      host,
      pkgs,
      config,
      ...
    }:
    let
      nixOScfg = config;
    in
    {

      age.secrets.forgejo-runner-token = {
        rekeyFile = ./forgejo-runner-token.env.age;
      };

      # Split into a `podman` capability, later

      # virtualisation.podman = {
      #   enable = true;
      #
      #   defaultNetwork.settings = {
      #     dns_enabled = true;
      #     ipv6_enabled = true;
      #   };
      # };
      #
      # networking.firewall.interfaces."podman*".allowedUDPPorts = [ 53 ];

      services.gitea-actions-runner = {

        package = pkgs.forgejo-runner;

        instances.default = {
          enable = true;
          name = host.hostName;
          url = "https://git.desertflood.com";
          tokenFile = nixOScfg.age.secrets.forgejo-runner-token.path;

          labels = [
            # provide a debian base with nodejs for actions
            "debian-latest:docker://node:24-trixie"

            # fake the ubuntu name, because node provides no ubuntu builds
            "ubuntu-latest:docker://node:24-trixie"

            # mimic the GitHub runners
            # should be compatible with most actions while remaining relatively small
            "ubuntu-22.04:docker://ghcr.io/catthehacker/ubuntu:act-22.04"
          ];
        };

      };

    };
}
