{
  inputs,
  config,
  lib,
  ...
}:
let
  flakeCfg = config;
in
{
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
        netCfg = dfCfg.networking;
        svcsConfig = dfCfg.services;
        svcsNetCfg = netCfg.services;
      in
      {

        imports = [ ];

        options = {

          desertflood.services.linkwarden = {
            enable = lib.mkEnableOption "Linkwarden, Bookmarks, Evolved";
          };
        };

        config = lib.mkIf svcsConfig.linkwarden.enable {

          desertflood.networking.services.linkwarden = { };

          age.secrets.linkwarden.rekeyFile = ./secrets.env.age;

          services.linkwarden = {
            enable = true;

            port = 12568; # uv run --with port4me python -m port4me --tool=linkwarden
            host = "127.0.0.1";

            environment = {
              NEXT_PUBLIC_DISABLE_REGISTRATION = "true";
              NEXT_PUBLIC_CREDENTIALS_ENABLED = "false";
              NEXT_PUBLIC_EMAIL_PROVIDER = "true";
              EMAIL_FROM = "admin@desertflood.com";
              BASE_URL = "${svcsNetCfg.linkwarden.fullURL}";
              NEXT_PUBLIC_AUTHENTIK_ENABLED = "true";
              AUTHENTIK_CUSTOM_NAME = "authentik Desertflood";
              AUTHENTIK_ISSUER = "https://sso.desertflood.link/application/o/linkwarden";
              NEXTAUTH_URL = "${svcsNetCfg.linkwarden.fullURL}api/v1/auth";
            };

            environmentFile = "${nixOScfg.age.secrets.linkwarden.path}";
          };

        };

      };

  };

}
