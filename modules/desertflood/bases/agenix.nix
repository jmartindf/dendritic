{ inputs, ... }:
{
  flake.modules.nixos.agenix =
    { config, ... }:
    let
      cfg = config;
    in
    {
      imports = builtins.traceVerbose "flake.modules.nixos.agenix active" [
        inputs.agenix.nixosModules.default
        inputs.agenix-rekey.nixosModules.default
      ];

      age.rekey = {
        storageMode = "local";
        masterIdentities = [
          ../../../.secrets/identity-yubikey1.pub
          ../../../.secrets/identity-yubikey2.pub
        ];
        localStorageDir = ../../../.secrets/${cfg.networking.hostName};
      };
    };
}
