set unstable := true

build := "nom"
toplevel := "config.system.build.toplevel"
rsyncFlags := "-rav --exclude=\".jj\" --delete --delete-excluded"

[private]
default:
    just --list

[group("richard")]
rsync:
    rsync {{ rsyncFlags }} ./ richard:/home/nixos/dendritic/

[group("richard")]
build:
    {{ build }} build .#.nixosConfigurations.richard.{{ toplevel }}

[group("richard")]
deploy: build rsync
    nixos-rebuild-ng switch --flake . --target-host root@richard.home.thosemartins.family
