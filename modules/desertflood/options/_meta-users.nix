# Specify the available options for configuring users on hosts
{
  lib,
  ...
}:
let
  inherit (lib) types;
  emailOption =
    { name, ... }:
    {
      options = {
        label = lib.mkOption {
          type = types.str;
          example = "family";
          description = "The user-visible name or description of the email account.";
        };
        email = lib.mkOption {
          type = types.str;
          example = "user@familydomain.com";
          description = "The actual email address to use";
        };
      };
      config = {
        label = lib.mkDefault name;
      };
    };
in
{ name, config, ... }:
{
  options = {

    username = lib.mkOption {
      type = types.str;
      example = "smith";
      description = "The name of the user account. If undefined, the name of the attribute set will be used.";
    };

    fullName = lib.mkOption {
      type = types.str;
      default = "";
      example = "John Q. Smith";
      description = "A short description of the user account, typically the user’s full name. This is actually the “GECOS” or “comment” field in `/etc/passwd`.";
    };

    emails = lib.mkOption {
      type = types.attrsOf (types.submodule emailOption);
      default = null;
      description = "The user's available email addresses.";
    };

    authorizedKeys = lib.mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = "SSH public keys that can be used to login";
    };

    homedir = lib.mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "The user’s home directory.";
    };

    root = lib.mkEnableOption "treating user as root";

    superuser = lib.mkEnableOption "root-like powers without being root";

    profileName = lib.mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "The home manager configuration in the flake";
    };

    proileConfigDir = lib.mkOption {
      type = types.nullOr types.str;
      default = null;
      description = "Where the flake is stored on the local system";
    };

    darwinPassthru = lib.mkOption {
      type = types.attrsOf types.anything;
      default = { };
    };

    extraOptions = lib.mkOption {
      type = types.attrsOf types.anything;
      description = "Extra options passed to users.users.<name>. These will overwrite any options already defined.";
      default = { };
    };

    profileTheme = {
      name = lib.mkOption {
        type = types.nullOr types.str;
        default = null;
        description = "The user theme to apply to starship and fish";
      };

      enable = lib.mkEnableOption "using the profile theme";
      enableFish = lib.mkEnableOption "the profile theme in fish";
      enableStarship = lib.mkEnableOption "the profile theme in starship";
    };
  };

  config = lib.mkMerge [
    { username = lib.mkDefault name; }
    {
      profileTheme.name = "felt-green-df";
    }
  ];
}
