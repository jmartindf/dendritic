{
  den,
  df,
  lib,
  ...
}:
let
  myTimezone = "America/Phoenix";
  myLocale = "en_US.UTF-8";
in
{

  # Home Manager is enabled on a host when one of its users has the
  # `homeManager` class. Users used to default to that class; they now
  # default to `user`, so opt every user back in.
  den.schema.user.classes = lib.mkDefault [ "homeManager" ];

  den.default = {

    includes = [
      # define users at OS and Home levels.
      den.batteries.define-user
      # enable specific unfree packages
      (den.batteries.unfree [
        "1password-cli"
        "sftpgo"
      ])
      df.base
    ];

    darwin = {
      system.stateVersion = 5;
      time.timeZone = myTimezone;
    };

    nixos = {
      system.stateVersion = "25.05";
      time.timeZone = myTimezone;
      i18n.defaultLocale = myLocale;
    };

    homeManager = {
      home.stateVersion = "23.11";
      # targets.darwin.defaults.NSGlobalDomain.AppleLocale = myLocale;
    };
  };

}
