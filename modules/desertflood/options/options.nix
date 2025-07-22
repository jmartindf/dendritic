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
