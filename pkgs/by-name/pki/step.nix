{
  lib,
  pki,
  step-cli,
  writeTextFile,
  writeShellApplication,
}:
let
  stepConfig = writeTextFile {
    name = "step-defaults.json";
    text = builtins.toJSON {
      ca-url = "https://pki.desertflood.link";
      fingerprint = "be95020a50bc30002b6f5a2ea3cd827b169412235192adeb3296a827d0036e00";
      root = "${pki.rootCert}";
    };
  };
in
writeShellApplication {
  name = "step";
  text = # bash
    ''
      ${lib.getExe step-cli} --config="${stepConfig}" "$@"
    '';
}
