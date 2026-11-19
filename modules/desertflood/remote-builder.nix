{ den, ... }:
let
  inherit (den.lib.policy) pipe;
in
{
  df.remote-builder.nixos = { builder-clients, lib, ... }: {
    nix.settings.trusted-users = [ "builder" ];

    users.users.builder = {
      isNormalUser = true;
      openssh.authorizedKeys.keys = lib.attrsets.catAttrs "key" builder-clients;
    };
  };

  # Use quirks and pipes to define which machines can use this machine as a remote builder
  den = {
    quirks.builder-clients = {
      description = "Machines that need to use a remote Nix builder";
    };

    # Collect the "builder-clients" quirk from each host
    policies.collect-builder-clients = { host, ... }: [
      (pipe.from "builder-clients" [
        (pipe.collect ({ host, ... }: true))
      ])
    ];

    schema.host.includes = [
      den.policies.collect-builder-clients
    ];
  };

}
