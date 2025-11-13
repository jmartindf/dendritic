set unstable := true

defaultHost := "richard"
build := "nom"
toplevel := "config.system.build.toplevel"
rsyncFlags := "-v --links --perms --recursive --times  --exclude=\".jj\" --exclude=\"derivations\" --delete --delete-excluded"
buildFlags := ""
atticCmd := "./attic-nofail.fish"
atticOptions := "-j3"
atticDestination := "desertflood:df-test"

[private]
default:
    just --list

devshell:
    echo "run 'nix develop .#'"

[group("send")]
rsync host=defaultHost:
    rsync {{ rsyncFlags }} ./ nixos@{{ host }}:/home/nixos/dendritic/

[group("build")]
build host=defaultHost:
    {{ build }} build {{ buildFlags }} --out-link ./derivations/{{ host }} .#.nixosConfigurations.{{ host }}.{{ toplevel }}

[group("build")]
buildAll: (build "richard") (build "fossil") (build "france") (build "everest")

[group("deploy")]
deploy host=defaultHost: (build host) (rsync host) (push host)
    # nixos-rebuild-ng switch --flake . --target-host root@{{ host }}
    ssh nixos@{{ host }} -- nixos-rebuild-ng switch --sudo

[group("deploy")]
deployAll: (deploy "richard") (deploy "fossil") (deploy "france") (deploy "everest")

[group("push")]
push host=defaultHost:
    {{ atticCmd }} push "{{ atticOptions }}" "{{ atticDestination }}" derivations/{{ host }}/

[group("push")]
pushAll: (push "richard") (push "fossil") (push "france") (push "everest")
