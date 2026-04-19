{ den, df, ... }:
let
  sysPackages = pkgs: [
    pkgs.coreutils-full
    pkgs.dust # du + rust = dust. Like du but more intuitive
    pkgs.findutils
    pkgs.gdu # TUI disk usage analyzer
    pkgs.glow # Render markdown on the CLI, with pizzazz!
    pkgs.gnused
    pkgs.less # More advanced file pager than 'more'
    pkgs.ntfy-sh # Push notifications made easy
  ];

  osContext = den.lib.take.exactly (
    { OS, host }:
    {
      ${host.class} = builtins.traceVerbose "coreutils.${host.class} active" (
        { pkgs, ... }:
        {
          config.environment.systemPackages = sysPackages pkgs;
        }
      );
    }
  );
in
{
  df.cli.includes = [
    osContext
    {
      homeManager =
        {
          pkgs,
          lib,
          ...
        }:
        {
          config = {
            programs = {

            };
          };
        };
    }
  ];
}
