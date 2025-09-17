set unstable := true

defaultHost := "richard"
build := "nom"
toplevel := "config.system.build.toplevel"
rsyncFlags := "-rav --exclude=\".jj\" --delete --delete-excluded"
buildFlags := "--no-link"

[private]
default:
    just --list

devshell:
    echo "run 'nix develop .#'"

[group("hosts")]
rsync host=defaultHost:
    rsync {{ rsyncFlags }} ./ {{ host }}:/home/nixos/dendritic/

[group("hosts")]
build host=defaultHost:
    {{ build }} build {{ buildFlags }} .#.nixosConfigurations.{{ host }}.{{ toplevel }}

[group("hosts")]
buildAll: (build "richard") (build "fossil") (build "france")

[group("hosts")]
deploy host=defaultHost: (build host) (rsync host)
    nixos-rebuild-ng switch --flake . --target-host root@{{ host }}.{{ if host == "france" { "df.fyi" } else { "home.thosemartins.family" } }}
