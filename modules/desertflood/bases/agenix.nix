{ inputs, ... }:
{
  df.agenix.nixos =
    { config, ... }:
    let
      cfg = config;
    in
    {
      imports = builtins.traceVerbose "df.agenix.nixos active" [
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
