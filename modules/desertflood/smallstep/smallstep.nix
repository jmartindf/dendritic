{ config, ... }:
let
  flakeCfg = config;
in
{
  flake.modules.nixos.smallstep =
    { pkgs, ... }:
    let
      cacert = pkgs.fetchurl flakeCfg.desertflood.step-ca.rootCert;

      step-defaults = pkgs.writeText "step-ca-defaults.json" (
        builtins.toJSON {
          ca-url = flakeCfg.desertflood.step-ca.url;
          inherit (flakeCfg.desertflood.step-ca) fingerprint;
          root = "${cacert}";
        }
      );
    in
    {

      security.pki.certificateFiles = [ cacert ];

      environment =
        let
          steppath = "step-ca";
        in
        {
          systemPackages = [
            pkgs.step-cli
          ];

          etc = {
            "${steppath}/certs/root_ca.crt".source = cacert;
            "${steppath}/config/defaults.json".source = step-defaults;
          };

          variables = {
            STEPPATH = "/etc/${steppath}";
          };
        };
    };
}
