{ den, ... }:
{
  df.cli = den.lib.parametric {
    description = "Everything related to the command line and TUIs";

    nixos = { };
    darwin = { };
    homeManager = { };
  };
}
