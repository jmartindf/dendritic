{
  fetchurl,
  writeTextFile,
}:
writeTextFile {
  name = "pkiroots.pem";
  text = fetchurl {
    url = "https://pki.desertflood.link/roots.pem";
    hash = "sha256-tgK+D2q/bJBZCDh+7Cf9ha2wSzIfh7n2HZi5Vif6g1k=";
    curlOpts = "--insecure";
  };
}
