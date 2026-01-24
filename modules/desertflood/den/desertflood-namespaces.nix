{ inputs, ... }:
{
  imports = [
    # create local `df` namespace. false: not flake exposed
    (inputs.den.namespace "df" false)
    # create shareable `dux` namespace (df/ux in the tradition of Apple’s A/UX). true: flake exposed
    (inputs.den.namespace "dux" true)
  ];
}
