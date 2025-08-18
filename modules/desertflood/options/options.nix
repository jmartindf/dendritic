{
  config,
  lib,
  ...
}:
let
  inherit (lib) types;
  flakeCfg = config;

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

  dfOptions = {

    networking = {
      webDomain = lib.mkOption {
        type = lib.types.str;
        description = "the default public web domain for nginx and whatnot";
      };

      webHost = lib.mkOption {
        type = lib.types.str;
        description = "the default public web domain (FQDN) for nginx and whatnot";
      };

      services =
        nixOScfg:
        lib.mkOption {
          description = "Describe the URLs for hosted services";
          default = { };
          type = lib.types.attrsOf (
            lib.types.submodule (
              { name, config, ... }:
              {

                options = {

                  protocol = lib.mkOption {
                    type = lib.types.str;
                    default = "https";
                    example = "http";
                    description = "The protocol to serve from";
                  };

                  domain = lib.mkOption {
                    type = lib.types.str;
                    description = "the default public web domain for nginx and whatnot";
                    default = flakeCfg.desertflood.networking.tailscaleDomain;
                  };

                  hostName = lib.mkOption {
                    type = lib.types.str;
                    description = "the default public web hostname for nginx and whatnot";
                    default = nixOScfg.desertflood.networking.hostName;
                  };

                  fqdn = lib.mkOption {
                    type = lib.types.str;
                    description = "the public FQDN for nginx and whatnot";
                    default = "${config.hostName}.${config.domain}";
                  };

                  path = lib.mkOption {
                    type = lib.types.str;
                    description = "The subpath (if any) that the service is served from";
                    default = "/${name}/";
                  };

                  fullURL = lib.mkOption {
                    type = lib.types.str;
                    default = "";
                    description = "FQDN + path";
                  };

                };

                config = {

                  path = lib.mkDefault "/${name}/";
                  hostName = lib.mkDefault (
                    lib.optionalString (nixOScfg.networking.hostName != "") nixOScfg.networking.hostName
                  );
                  domain = lib.mkDefault (
                    lib.optionalString (
                      flakeCfg.desertflood.networking.tailscaleDomain != ""
                    ) flakeCfg.desertflood.networking.tailscaleDomain
                  );

                  fqdn =
                    if config.hostName != "" && config.domain != "" then
                      "${config.hostName}.${config.domain}"
                    else
                      "${config.hostName}";

                  fullURL =
                    if config.fqdn != "" && config.path != "" then
                      "${config.protocol}://${config.fqdn}${config.path}"
                    else if config.fqdn != "" then
                      "${config.protocol}://${config.fqdn}"
                    else
                      "${config.protocol}://${config.hostName}";

                };
              }
            )
          );
        };
    };

    defaultUser = lib.mkOption {
      type = types.submodule userMeta;
      default = { };
      description = "The default user for this host, for flake-parts modules";
    };

    hostInfo = lib.mkOption {
      type = types.submodule hostMeta;
      default = { };
      description = "Basic facts about this host, for flake-parts modules";
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

    inherit (dfOptions) defaultUser;

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

    networking = {
      tailscaleDomain = lib.mkOption {
        type = types.str;
        description = "The shared tailscale domain name";
      };
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
  };

  config = {

    flake.modules.nixos.nixos =
      { config, ... }:
      {

        options.desertflood = {
          inherit (dfOptions) defaultUser hostInfo;

          networking = {
            inherit (dfOptions.networking) webDomain webHost;
            services = dfOptions.networking.services config;
          };
        };

      };

    flake.modules.darwin.darwin = {

      options.desertflood = {
        inherit (dfOptions) defaultUser hostInfo;

        networking = {
          inherit (dfOptions.networking) webDomain webHost services;
        };
      };

    };

  };
}
