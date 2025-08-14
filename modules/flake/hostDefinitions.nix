{ inputs, ... }:
{
  config = {

    flake = {

      nixosConfigurations = {
        richard = inputs.self.lib.mk-os.linux "richard";
        fossil = inputs.self.lib.mk-os.linux "fossil";
      };

    };

  };

}
