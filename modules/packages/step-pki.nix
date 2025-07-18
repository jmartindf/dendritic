let
  pkiRootCert =
    pkgs:
    pkgs.fetchurl {
      url = "https://pki.desertflood.link/roots.pem";
      hash = "sha256-tgK+D2q/bJBZCDh+7Cf9ha2wSzIfh7n2HZi5Vif6g1k=";
      curlOpts = "--insecure";
    };
  stepConfig =
    pkgs:
    pkgs.writeTextFile {
      name = "step-defaults.json";
      text = builtins.toJSON {
        ca-url = "https://pki.desertflood.link";
        fingerprint = "be95020a50bc30002b6f5a2ea3cd827b169412235192adeb3296a827d0036e00";
        root = "${pkiRootCert pkgs}";
      };
    };
  step =
    pkgs:
    pkgs.writeShellApplication {
      name = "step";
      text = # bash
        ''
          ${pkgs.lib.getExe pkgs.step-cli} --config="${stepConfig pkgs}" "$@"
        '';
    };
  signEm =
    pkgs:
    pkgs.writeShellApplication {
      name = "step-ssh-sign-host-keys";
      text = # bash
        ''
          fqdn="richard.home.thosemartins.family"
          if [[ -a /etc/ssh/ssh_host_ed25519_key ]];
          then
          ${pkgs.lib.getExe (step pkgs)} ssh certificate --host --host-id machine --sign "$fqdn" /etc/ssh/ssh_host_ed25519_key.pub
          fi
          if [[ -a /etc/ssh/ssh_host_rsa_key ]];
          then
          ${pkgs.lib.getExe (step pkgs)} ssh certificate --host --host-id machine --sign "$fqdn" /etc/ssh/ssh_host_rsa_key.pub
          fi
        '';
    };
in
{
  perSystem =
    { pkgs, ... }:
    {

      packages = {
        step = step pkgs;
        signEm = signEm pkgs;
        pkiRootCert = pkiRootCert pkgs;
      };

    };
}
