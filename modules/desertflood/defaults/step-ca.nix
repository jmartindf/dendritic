_:
let
  url = "https://pki.desertflood.link";
in
{
  config.desertflood.step-ca = {
    provisioner = "joe@desertflood.com";
    inherit url;
    fingerprint = "be95020a50bc30002b6f5a2ea3cd827b169412235192adeb3296a827d0036e00";

    rootCert = {
      name = "roots.pem";
      version = "unstable-2025-07-24";
      url = "${url}/roots.pem";
      hash = "sha256-tgK+D2q/bJBZCDh+7Cf9ha2wSzIfh7n2HZi5Vif6g1k=";
      curlOpts = "--insecure";
    };
  };
}
