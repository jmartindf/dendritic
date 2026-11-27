{
  lib,
  ...
}:
let
  inherit (lib) types;

  userMeta = import ./_meta-users.nix {
    inherit lib;
  };
  globalAttrSet = lib.mkOption {
    type = lib.types.attrsOf lib.types.anything;
    default = { };
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

  dfOptions = {

    networking = {
      tailscaleDomain = lib.mkOption {
        type = types.str;
        description = "The shared tailscale domain name";
      };

      webHost = lib.mkOption {
        type = lib.types.str;
        description = "the default public web domain (FQDN) for nginx and whatnot";
      };

      FQDN = lib.mkOption {
        type = lib.types.str;
        description = "the default public web domain (FQDN) for nginx and whatnot";
      };

      tsFQDN = lib.mkOption {
        type = lib.types.str;
        description = "the tailscale domain (FQDN) for nginx and whatnot";
      };

      extraFQDNs = lib.mkOption {
        type = lib.types.listOf lib.types.str;
        description = "Any additional FQDNs that should/could be used";
        default = [ ];
      };

    };

    defaultUser = lib.mkOption {
      type = types.submodule userMeta;
      default = { };
      description = "The default user for this host, for flake-parts modules";
    };
  };

  users = {
    users = lib.mkOption {
      type = types.attrsOf (types.submodule userMeta);
      default = { };
      description = "Details of user accounts that can be shared across hosts.";
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

  step-ca = {
    provisioner = lib.mkOption {
      type = types.str;
      description = "Which provisioner to use for creating certificates";
    };

    url = lib.mkOption {
      type = types.str;
      description = "What is the URL for the smallstep ca";
    };

    fingerprint = lib.mkOption {
      type = types.str;
      description = "The fingerprint of the smallstep ca’s root certificate";
    };

    rootCert = lib.mkOption {
      type = types.attrsOf types.anything;
      default = { };
      description = "The necessary info to get the root certificate using `fetchurl`";
    };
  };
in
{
  options.desertflood = {

    globals = globalAttrSet;

    inherit (dfOptions) defaultUser networking;
    inherit
      users
      builderKeys
      secrets
      step-ca
      ;
  };

  config = {

    df.df-options.nixos = {

      options.desertflood = {

        globals = globalAttrSet;
        inherit (dfOptions) defaultUser;

        networking = {
          inherit (dfOptions.networking)
            webHost
            tailscaleDomain
            FQDN
            tsFQDN
            extraFQDNs
            ;
        };
      };

    };

    den.schema.host = { host, lib, ... }: {
      options = {

        domain = lib.mkOption {
          type = types.nullOr types.str;
          default = null;
          example = "desertflood.com";
          description = "The domain";
        };

        tsdomain = lib.mkOption {
          type = types.nullOr types.str;
          default = null;
          example = "random-word.ts.net";
          description = "The shared tailscale domain name";
        };

        fqdn = lib.mkOption {
          type = types.nullOr types.str;
          default = null;
          description = ''
            The fully qualified domain name (FQDN) of this host. By default, it is the result of combining `{{host}}.hostName` and `{{host}}.domain`.
          '';
        };

        tsFQDN = lib.mkOption {
          type = lib.types.str;
          description = ''
            The fully qualified domain name (FQDN) of this host. By default, it is the result of combining `{{host}}.hostName` and `{{host}}.tsdomain`.
          '';
        };

        webFQDN = lib.mkOption {
          type = lib.types.str;
          description = ''
            The fully qualified domain name (FQDN) of this host for websites. By default, it is the same as `{{host}}.fqdn`.
          '';
        };

        extraFQDNs = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          description = "Any additional FQDNs that should/could be used";
          default = [ ];
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
      };

      config = {
        domain = lib.mkDefault host.desertflood.globals.domain;
        tsdomain = lib.mkDefault host.desertflood.globals.tailscaleDomain;

        fqdn =
          if (host.hostName != "" && host.domain != "") then
            lib.mkDefault "${host.hostName}.${host.domain}"
          else
            lib.mkDefault null;

        webFQDN = lib.mkDefault host.fqdn;

        tsFQDN =
          if (host.hostName != "" && host.tsdomain != "") then
            lib.mkDefault "${host.hostName}.${host.tsdomain}"
          else
            lib.mkDefault null;
      };

    };

    den.schema.conf = {
      options.desertflood = {

        globals = globalAttrSet;
        inherit (dfOptions) defaultUser;
        inherit
          users
          builderKeys
          secrets
          step-ca
          ;

        networking = {
          inherit (dfOptions.networking)
            webHost
            tailscaleDomain
            FQDN
            tsFQDN
            extraFQDNs
            ;
        };
      };
    };
  };
}
