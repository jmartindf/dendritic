{ lib, ... }:
{
  flake.modules.nixos.nixos =
    { config, pkgs, ... }:
    {

      imports = [
      ];

      options = {
        desertflood.services.postgresql.enable = lib.mkEnableOption "PostgreSQL 17 database";
      };

      config = lib.mkIf config.desertflood.services.postgresql.enable {

        desertflood.networking.services.postgresql = { };

        services = {

          postgresql = {
            enable = true;
            package = pkgs.postgresql_17;

            # system root user is postgres admin user (`postgres`)
            identMap = # identMap
              ''
                postgres root postgres
              '';
          };

        }; # end `services` block

      }; # end Nix OS module config block

    }; # end `postgresql` Nix OS module
}
