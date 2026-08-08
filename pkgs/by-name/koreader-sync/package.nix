{
  fetchFromGitHub,
  makeWrapper,
  pkgs,
  ...
}:

pkgs.stdenv.mkDerivation rec {

  pname = "koreader-sync";
  version = "0.2.3";

  src = fetchFromGitHub {
    owner = "nperez0111";
    repo = "${pname}";
    rev = "v${version}";
    hash = "sha256-JXTVCPNDVEZG9W6o5vR0hCPuyO4IZazYtpgt1u7Ow8o=";
  };

  nativeBuildInputs = [
    pkgs.bun2nix.hook
    makeWrapper
  ];

  bunDeps = pkgs.bun2nix.fetchBunDeps {
    bunNix = ./bun.nix;
  };

  bunInstallFlags = [ "--production" ];

  dontRunLifecycleScripts = true;

  buildPhase = # shell
    ''
      NODE_ENV=production bun build ./src/index.tsx --target=bun --sourcemap=inline --minify --outfile=server.js
    '';

  installPhase = # shell
    ''
      runHook preInstall
      mkdir -p $out/bin
      substituteInPlace server.js --replace-fail "\"./public\"" "\"$out/public\"";
      makeWrapper ${pkgs.bun}/bin/bun $out/bin/${pname} --add-flags "run $out/server.js"
      cp -R ./public $out/public
      cp server.js $out
      runHook postInstall
    '';
}
