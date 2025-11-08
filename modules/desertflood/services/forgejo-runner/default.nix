_: {
  # SPDX-FileCopyrightText: 2025 Joe Martin <joe@desertflood.com>
  # SPDX-License-Identifier: BlueOak-1.0.0

  imports = [ ];

  options = { };

  config = {

    flake.modules.nixos.services =
      {
        lib,
        pkgs,
        config,
        ...
      }:
      let
        nixOScfg = config;
        dfCfg = nixOScfg.desertflood;
        svcsConfig = dfCfg.services;
      in
      {

        imports = [ ];

        options = {

          desertflood.services.forgejo-runner = {
            enable = lib.mkEnableOption "a daemon that fetches workflows to run from a Forgejo instance and executes them";
          };
        };

        config = lib.mkIf svcsConfig.forgejo-runner.enable {

          desertflood.networking.services.forgejo-runner = { };

          age.secrets.forgejo-runner-token = {
            rekeyFile = ./forgejo-runner-token.env.age;
          };

          virtualisation.podman = {
            enable = true;

            defaultNetwork.settings = {
              dns_enabled = true;
              ipv6_enabled = true;
            };
          };

          networking.firewall.interfaces."podman*".allowedUDPPorts = [ 53 ];

          services.gitea-actions-runner = {

            package = pkgs.forgejo-actions-runner;

            instances.default = {
              enable = true;
              name = nixOScfg.networking.hostName;
              url = "https://git.desertflood.com";
              tokenFile = nixOScfg.age.secrets.forgejo-runner-token.path;

              labels = [
                # provide a debian base with nodejs for actions
                "debian-latest:podman://node:24-trixie"

                # fake the ubuntu name, because node provides no ubuntu builds
                "ubuntu-latest:podman://node:24-trixie"

                # mimic the GitHub runners
                # should be compatible with most actions while remaining relatively small
                "ubuntu-22.04:podman://ghcr.io/catthehacker/ubuntu:act-22.04"
              ];
            };

          };

        };

      };

  };

}
