# SPDX-FileCopyrightText: 2025 Joe Martin <joe@desertflood.com>
# SPDX-License-Identifier: BlueOak-1.0.0
{ lib, ... }:
{
  df.services.traefik.nixos =
    {
      config,
      pkgs,
      ...
    }:
    let
      cfg = config;
      myTraefikCfg = config.desertflood.services.traefik;
      traefikCfg = cfg.services.traefik;

      toTOML = name: attrSet: (pkgs.formats.toml { }).generate "${name}.toml" attrSet;

      generateRules = lib.mapAttrs' (
        ruleName: ruleConfig: {
          name = "traefik/${ruleName}.toml";
          value = {
            source = toTOML ruleName ruleConfig;
          };
        }
      );

      traefikConfigFile = toTOML "config" traefikCfg.staticConfigOptions;
      traefikDynamicConfigFile = toTOML "common" traefikCfg.dynamicConfigOptions;
    in
    {
      config = {

        services = {
          traefik = {
            enable = true;
            package = pkgs.traefik;

            staticConfigFile = traefikConfigFile;
            dynamicConfigFile = traefikDynamicConfigFile;
          };
        };

        environment.etc = generateRules myTraefikCfg.rules;
      };
    };
}
