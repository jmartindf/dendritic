{
  lib,
  inputs,
  config,
  ...
}:
{
  options.desertflood.lib = lib.mkOption {
    internal = true;
    visible = false;
    type = lib.types.attrsOf lib.types.raw;
  };

  config.desertflood.lib =
    let
      mkServiceSecrets =
        secretsPath: secretHolder: names:
        lib.genAttrs names (name: {
          rekeyFile = "${secretsPath}/${name}.age";
          owner = secretHolder;
          group = secretHolder;
        });
      df-lib = { inherit mkServiceSecrets; };
    in
    df-lib;
}
