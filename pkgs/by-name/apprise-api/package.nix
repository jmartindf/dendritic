{
  lib,
  fetchFromGitHub,
  python313Packages,
  bash,
  python313,
}:

let
  version = "1.3.0";
  python = python313Packages;

  dependencies = with python; [
    apprise
    cryptography
    django
    django-prometheus
    gevent
    gntp
    paho-mqtt
    requests
  ];

in
python.buildPythonApplication {
  pname = "apprise-api";
  inherit version;

  src = fetchFromGitHub {
    owner = "caronc";
    repo = "apprise-api";
    rev = "v${version}";
    sha256 = "sha256-tFhlBKRliGyx0t2k/81Q8igdyIpMKagkTKgTXk+9tus=";
  };
  inherit dependencies;
  format = "other";

  propagatedBuildInputs = [
    python313Packages.gunicorn
    python313Packages.django
  ];

  installPhase =
    let
      pythonPath = python.makePythonPath dependencies;
    in
    # bash
    ''
      runHook preInstall

      substituteInPlace apprise_api/gunicorn.conf.py --replace-fail "/opt/apprise/webapp" "$out/webapp"

      mkdir -p $out/bin
      cp -r apprise_api $out/webapp

      echo "Creating gunicorn wrapper..."
      cat <<EOF > $out/bin/apprise-api
      #!${bash}/bin/bash

      # Execute gunicorn, passing along any arguments
      # Ensure the gunicorn package is in propagatedBuildInputs
      export PYTHONPATH=${pythonPath}
      exec ${python313Packages.gunicorn}/bin/gunicorn -c "$out/webapp/gunicorn.conf.py" "\$@" core.wsgi
      EOF
      chmod +x $out/bin/apprise-api

      runHook postInstall
    '';

  meta = {
    description = "A lightweight REST framework that wraps the Apprise Notification Library";
    homepage = "https://github.com/caronc/apprise-api";
    license = lib.licenses.mit;
  };
}
