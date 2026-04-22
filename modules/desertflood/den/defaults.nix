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

  # enable home-manager by default for all users
  # Does nothing for hosts that have no users with `homeManager` class
  den.schema.user.classes = lib.mkDefault [ "homeManager" ];

  den.ctx.host.includes = [
    # enable specific unfree packages
    # (den._.unfree [
    #   "1password-cli"
    #   "sftpgo"
    # ])
    # df.base
  ];
  #
  den.default = {

    includes = [
      # define users at OS and Home levels.
      den.provides.define-user

      # enable specific unfree packages
      (den.provides.unfree [
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
