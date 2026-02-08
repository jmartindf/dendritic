# Specify the available options for describing hosts
{
  lib,
  ...
}:
let
  inherit (lib) types;
in
{ name, config, ... }:
{
  options = {

    hostName = lib.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "www";
      description = "The name of the machine";
    };

    domain = lib.mkOption {
      type = types.nullOr types.str;
      default = null;
      example = "desertflood.com";
      description = "The domain";
    };

    fqdn = lib.mkOption {
      type = types.nullOr types.str;
      default = null;
      description = ''
        The fully qualified domain name (FQDN) of this host. By default, it is the result of combining `{{host}}.hostName` and `{{host}}.domain`.
      '';
    };

    live = lib.mkOption {
      type = types.bool;
      default = false;
      description = "This system is hosting live services";
    };

    remote = lib.mkOption {
      type = types.bool;
      default = false;
      description = "This system is usually out of reach";
    };

    system = lib.mkOption {
      type = types.enum [
        "x86_64-linux"
        "aarch64-linux"
        "aarch64-darwin"
      ];
      default = "x86_64-linux";
      description = "System architecture";
    };
  };

  config = {
    hostName = lib.mkDefault name;
    fqdn =
      if (config.hostName != "" && config.domain != "") then
        lib.mkDefault "${config.hostName}.${config.domain}"
      else
        lib.mkDefault null;
  };
}
