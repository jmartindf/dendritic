{ ... }:
let
  vackup =
    {
      bash,
      docker_28,
      fetchFromGitHub,
      lib,
      makeWrapper,
      stdenv,
    }:
    stdenv.mkDerivation {
      pname = "vackup";
      version = "0-unstable-2025-07-19";
      src = fetchFromGitHub {
        owner = "jmartindf";
        repo = "docker-vackup";
        rev = "b060ac3c97fae6faadf7dc35bcdd1ebfdd58f1a1";
        hash = "sha256-9pbxGWDXDxZOM49XVsNrj9zzGk6OHFhZXaorA6+0wPo=";
      };

      nativeBuildInputs = [ makeWrapper ];

      patchPhase = ''
        substituteInPlace vackup --replace-fail "/bin/bash" "${lib.getExe bash}"
      '';

      dontConfigure = true;

      installPhase = ''
        runHook preInstall

        install -Dm755 vackup "$out/bin/vackup"

        wrapProgram "$out/bin/vackup" \
          --suffix PATH : ${lib.makeBinPath [ docker_28 ]}

        runHook postInstall
      '';

      meta = {
        homepage = "https://github.com/jmartindf/docker-vackup/blob/main/README.md";
        description = "Script to easily backup and restore docker volumes (patched with PRs)";
        license = lib.licenses.unlicense;
        mainProgram = "vackup";
      };
    };
in
{
  perSystem =
    { pkgs, ... }:
    {

      packages = {
        vackup = pkgs.callPackage vackup { };
      };

    };
}
