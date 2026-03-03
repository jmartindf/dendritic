_:
let
  globals = {

    tailscaleIPs = {
      everest = "100.79.239.108";
      firewalla = "100.125.134.86";
      fossil = "100.64.101.96";
      france = "100.110.64.44";
      homeassistant = "100.102.35.69";
      hermes = "100.87.9.119";
      mark = "100.80.91.96";
      masto-es = "100.115.8.118";
      mastodon = "100.78.113.57";
      pikvm = "100.73.57.59";
      pve = "100.81.1.122";
      richard = "100.85.174.97";
      underworld = "100.121.115.41";
    };

    publicIPs = {
      france.ip4 = "5.78.135.35";
      france.ip6 = "2a01:4ff:1f0:a0b3::1";
    };

    uids = {
    };

    ports = {
      bluesky-pds = 36825;
      caddy-static = 10535;
      sftpgo-http = 42697; # uv run --with port4me python -m port4me --tool=httpd --user sftpgo
      loki = 3100;
      alloy = 3030;
      acme-dns = 26579; # uv run --with port4me python -m port4me --tool=acme-dns --user france
      kosync-dotnet = 24730; # uv run --with port4me python -m port4me --tool=kosync-dotnet
    };

    paths = {
      cacheHTML = "/srv/www/html-cache";
      staticHTML = "/srv/www/html";
    };

    endpoints = {
      loki_write = "https://france.manticore-mark.ts.net/loki/api/v1/push";
      prometheus_write = "https://france.manticore-mark.ts.net/prometheus/api/v1/write";
    };
  };
in
{

  flake.modules.nixos.nixos = {

    config.desertflood.globals = globals;

  };

}
