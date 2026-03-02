{
  lib,
  buildDotnetModule,
  dotnetCorePackages,
  fetchFromGitHub,
}:

buildDotnetModule rec {
  pname = "kosync-dotnet";
  version = "1.5.1";

  src = fetchFromGitHub {
    owner = "jberlyn";
    repo = "kosync-dotnet";
    rev = "v${version}";
    hash = "sha256-sh6qPNjju9zQJV6CP7JzBax/50CjmnG0GKSGKDjILvE=";
  };

  projectFile = "Kosync.csproj";
  nugetDeps = ./deps.json; # File generated with `nix-build -A kosync-dotnet.passthru.fetch-deps`.

  dotnet-sdk = dotnetCorePackages.sdk_8_0;
  dotnet-runtime = dotnetCorePackages.aspnetcore_8_0;

  # makeWrapperArgs = [
  #   # "--set DOTNET_WEBROOT ${placeholder "out"}/lib/lubelogger/wwwroot"
  # ];

  # executables = [ "Kosync.dll" ]; # This wraps "$out/lib/$pname/foo" to `$out/bin/foo`.

  postFixup = # sh
    ''
      makeWrapper ${dotnetCorePackages.aspnetcore_8_0}/bin/dotnet $out/Kosync \
      --add-flags "$out/Kosync.dll"
    '';

  meta = {
    description = "A .NET implementation of the KOReader sync server";
    longDescription = ''
      kosync-dotnet is a self-hostable implementation of the KOReader sync server built with .NET. It aims to extend the existing functionality of the official koreader-sync-server.

      Users of KOReader can register a user on this synchronisation server and use the inbuilt Progress sync plugin to keep all reading progress synchronised between devices.

      All data is stored inside a LiteDB database file.
    '';
    homepage = "https://github.com/jberlyn/kosync-dotnet";
    changelog = "https://github.com/jberlyn/kosync-dotnet/releases/tag/v${version}";
    license = lib.licenses.gpl3Only;
    # maintainers = with lib.maintainers; [ ];
    mainProgram = "Kosync";
    platforms = lib.platforms.all;
  };
}
