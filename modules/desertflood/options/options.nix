{
  lib,
  ...
}:
let
  inherit (lib) types;

  hostMeta = import ./_meta-hosts.nix {
    inherit lib;
  };
  userMeta = import ./_meta-users.nix {
    inherit lib;
  };
  publicKeys =
    { name, ... }:
    {
      options = {
        label = lib.mkOption {
          type = types.str;
          example = "psyche";
          description = "The user-visible name or description of the SSH public key.";
        };
        publicKey = lib.mkOption {
          type = types.str;
          description = "The actual public key to use";
        };
      };
      config = {
        label = lib.mkDefault name;
      };
    };
in
{
  options.desertflood = {

    users = {
      users = lib.mkOption {
        type = types.attrsOf (types.submodule userMeta);
        default = { };
        description = "Details of user accounts that can be shared across hosts.";
      };
    };

    hosts = {
      hosts = lib.mkOption {
        type = types.attrsOf (types.submodule hostMeta);
        default = { };
        description = "Details of the various hosts that can be created.";
      };
    };

    builderKeys = {
      builderKeys = lib.mkOption {
        type = types.attrsOf (types.submodule publicKeys);
        default = { };
        description = "Available machines that may want to use a remote Nix builder";
      };
    };

    secrets = lib.mkOption {
      type = types.attrsOf types.anything;
      default = { };
      description = "Secrets to use in age";
    };
  };

  config = {

    flake.modules.nixos.nixos.options.desertflood = {

      defaultUser = lib.mkOption {
        type = types.submodule userMeta;
        default = { };
        description = "The default user for this host";
      };

      hostInfo = lib.mkOption {
        type = types.submodule hostMeta;
        default = { };
        description = "Basic facts about this host";
      };

    };

    flake.modules.darwin.darwin.options.desertflood = {

      defaultUser = lib.mkOption {
        type = types.submodule userMeta;
        default = { };
        description = "The default user for this host";
      };

      hostInfo = lib.mkOption {
        type = types.submodule hostMeta;
        default = { };
        description = "Basic facts about this host";
      };

    };

  };
}
