{ config, ... }:
let
  flakeCfg = config;
in
{
  flake.modules.nixos.smallstep =
    { pkgs, ... }:
    let
      steppath = "step-ca";

      cacert = pkgs.fetchurl flakeCfg.desertflood.step-ca.rootCert;

      step-defaults = {
        ca-url = flakeCfg.desertflood.step-ca.url;
        inherit (flakeCfg.desertflood.step-ca) fingerprint;
        root = "${cacert}";
      };
    in
    {

      security.pki.certificateFiles = [ cacert ];

      environment = {
        systemPackages = [
          pkgs.step-cli
        ];

        etc = {
          "${steppath}/certs/root_ca.crt".source = cacert;

          "${steppath}/config/defaults.json".source = pkgs.writeText "step-ca-defaults.json" (
            builtins.toJSON step-defaults
          );
        };

        variables = {
          STEPPATH = "/etc/${steppath}";
        };
      };
    };
}
