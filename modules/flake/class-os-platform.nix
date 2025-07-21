{ ... }:
{
  config = {

    flake.modules = {

      nixos = {
        x86_64-linux = { };
        aarch64-linux = { };
        nixos = { };
      };

      darwin = {
        aarch64-darwin = { };
        darwin = { };
      };

    };

  };
}
