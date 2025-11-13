set unstable := true

defaultHost := "richard"
build := "nom"
toplevel := "config.system.build.toplevel"
rsyncFlags := "-rav --exclude=\".jj\" --delete --delete-excluded"
buildFlags := ""
atticCmd := "./attic-nofail.fish"
atticOptions := "-j3"
atticDestination := "desertflood:df-test"

[private]
default:
    just --list

devshell:
    echo "run 'nix develop .#'"

[group("hosts")]
rsync host=defaultHost:
    rsync {{ rsyncFlags }} ./ root@{{ host }}:/home/nixos/dendritic/

[group("hosts")]
build host=defaultHost:
    {{ build }} build {{ buildFlags }} --out-link ./derivations/{{ host }} .#.nixosConfigurations.{{ host }}.{{ toplevel }}

[group("hosts")]
buildAll: (build "richard") (build "fossil") (build "france")

[group("hosts")]
deploy host=defaultHost: (build host) (rsync host)
    nixos-rebuild-ng switch --flake . --target-host root@{{ host }}

[group("hosts")]
deployAll: (deploy "richard") (deploy "fossil") (deploy "france") (deploy "everest")

[group("push")]
push host=defaultHost:
    {{ atticCmd }} push "{{ atticOptions }}" "{{ atticDestination }}" derivations/{{ host }}/

[group("push")]
pushAll: (push "richard") (push "fossil") (push "france") (push "everest")
