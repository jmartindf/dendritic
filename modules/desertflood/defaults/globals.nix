_:
let
  globals = {

    tailscaleIPs = {
      everest = "100.79.239.108";
      firewalla = "100.125.134.86";
      fossil = "100.104.30.103";
      france = "100.110.64.44";
      mark = "100.80.91.96";
      masto-es = "100.115.8.118";
      mastodon = "100.78.113.57";
      pikvm = "100.73.57.59";
      richard = "100.85.174.97";
      underworld = "100.121.115.41";
      hermes = "100.87.9.119";
    };

    uids = {
    };

    ports = {
      bluesky-pds = 36825;
    };
  };
in
{

  flake.modules.nixos.nixos = {

    config.desertflood.globals = globals;

  };

}
