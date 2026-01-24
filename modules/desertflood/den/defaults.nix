{ den, df, ... }:
let
  myTimezone = "America/Phoenix";
  myLocale = "en_US.UTF-8";
in
{

  den.default = {

    includes = [
      # define users at OS and Home levels.
      den._.define-user
      # enable home-manager by default on all hosts
      # Does nothing for hosts that have no users with `homeManager` class
      den._.home-manager
      # enable specific unfree packages
      (den._.unfree [
        "1password-cli"
        "sftpgo"
      ])
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
