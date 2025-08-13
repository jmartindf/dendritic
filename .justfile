set unstable := true

defaultHost := "richard"
build := "nom"
toplevel := "config.system.build.toplevel"
rsyncFlags := "-rav --exclude=\".jj\" --delete --delete-excluded"
buildFlags := "--no-link"

[private]
default:
    just --list

[group("richard")]
rsync host=defaultHost:
    rsync {{ rsyncFlags }} ./ {{ host }}:/home/nixos/dendritic/

[group("richard")]
build host=defaultHost:
    {{ build }} build {{ buildFlags }} .#.nixosConfigurations.{{ host }}.{{ toplevel }}

[group("richard")]
deploy host=defaultHost: (build host) (rsync host)
    nixos-rebuild-ng switch --flake . --target-host root@{{ host }}.home.thosemartins.family
