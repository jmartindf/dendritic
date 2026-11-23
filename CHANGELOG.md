# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html)
(as much as possible for something that is a collection of system
configurations).

## [unreleased] - undated

### Changes

- chore: update dependencies
- refactor: remove unused node_exporter
- refactor: remove hostInfo options
- fix(deploy-rs): deploy all systems, but only the live ones
- feat(richard): mark as live


## [0.7.9] - 2026-11-21

### Changes

- chore: update sources

### Refactoring

- refactor(dockeras): remove unnecessary host arg
- refactor(docker): remove deprecated flake modules
- refactor(defaults): modernize battery syntax
- refactor(df/cli/tools/docker): cleanup and modernize aspect
- refactor(remote-builder): convert to den aspect with quirks and pipes
- refactor(proxmox-lxc): convert to den aspect
- refactor(desertflood/options): attach to den.schema.conf
- refactor(hostInfo): move options into den.schema.host
- refactor(services/prometheus): use Den aspects and quirks
- refactor(services/loki): use Den aspects and quirks
- refactor(hetzner-cloud): convert to den aspect
- refactor(services/grafana): convert to den aspect
- refactor(services/step-ca): convert to den aspect
- refactor(qemu-guest): convert to den aspect
- refactor(server-base): centralize root SSH authorized key

### Package Updates

- authentik:   2026.8.5 -> 2026.8.6
- caddy:   2.11.2 -> 2.11.9
- deploy-rs:   0.1.0 -> 1.0.0
- linkwarden:   2.15.1 -> 2.17.0
- lubelogger:   1.7.4 -> 1.7.5
- bind:   9.20.29-host -> 9.20.30-host
- brotli:   1.2.0 -> 1.2.1
- curl:   8.22.0 -> 8.23.0
- docker:   29.8.1 -> 29.9.3
- docker:   5.4.0 -> 5.6.1
- dotnet:   10.0.12 -> 10.0.14
- eza:   0.23.4 -> 0.23.5
- forgejo:   15.0.10 -> 15.0.12
- grafana:   13.0.9 -> 13.0.13
- grafana:   3.7.8 -> 3.7.9
- linux:   20260916-zstd -> 20261019-zstd
- nodejs:   22.23.3, 24.21.0 -> 24.22.3
- openssh:   10.5p1 -> 10.6p2
- postgresql:   17.11 -> 17.12
- python3:   3.13.15 -> 3.13.18
- rsync:   3.5.0 -> 3.5.2
- sqlite:   3.51.2 -> 3.53.3
- tailscale:   1.98.10 -> 1.104.5
- traefik:   3.7.13 -> 3.7.16
- tzdata:   2026c -> 2026f


## [0.7.8] - 2026-11-16

### Refactoring

- compat: migrate from Den 0.8 -> 0.20
- refactor(base-server): clean up the aspect and the admin user creation
- refactor(docker-server): clean up the aspect and the admin user creation


## [0.7.7] - 2026-11-16

### Changes

- feat(lubelogger): disable local logins
- feat(authentik): 2026.8.4 -> 2026.8.5


## [0.7.6] - 2026-10-17

### Changes

- feat(authentik): 2026.8.1 -> 2026.8.4


## [0.7.5] - 2026-10-17

### Changes

- feat: lubelogger 1.7.1 -> 1.7.4
- feat(lubelogger): enable local logins
- fix(lubelogger): don't copy me on all reminder emails
- feat(france): enable webdav for SFTPgo
- chore: update sources
- perf: use Nix channel archives

### Package Updates

- docker:   29.8.0 -> 29.8.1
- forgejo-lts:   15.0.9 -> 15.0.10
- grafana-loki:   3.7.7 -> 3.7.8
- lix:   2.95.2 -> 2.95.4
- lubelogger:   1.7.1 -> 1.7.4
- nix:   2.34.8 -> 2.34.9
- openssl:   3.6.4 -> 3.6.5
- systemd:   260.4 -> 260.5


## [0.7.4] - 2026-09-08

### Changes

- feat(authentik): 2026.5.6 -> 2026.8.1


## [0.7.3] - 2026-08-27

### Changes

- feat: lubelogger 1.7.0 -> 1.7.1
- chore: update sources
- fix(france): acme-dns does not have valid CAA records

 ### Software Updates

 - acl                                2.3.2 -> 2.4.0
 - attr                               2.5.2 -> 2.6.0
 - aws-c-http                         0.10.4 -> 0.11.0
 - aws-c-io                           0.22.0 -> 0.27.2
 - curl                               8.20.0 -> 8.21.0
 - docker                             29.6.1 -> 29.7.2
 - docker-compose                     5.1.4 -> 5.4.0
 - docker-containerd                  29.6.1 -> 29.7.2
 - docker-runc                        29.6.1 -> 29.7.2
 - docker-tini                        29.6.1 -> 29.7.2
 - dotnet-aspnetcore-runtime          10.0.8 -> 10.0.11
 - expat                              2.8.1 -> 2.8.3
 - forgejo-lts                        15.0.4 -> 15.0.7
 - forgejo-runner                     12.13.0 -> 12.13.2
 - grafana                            13.0.3 -> 13.0.7
 - grafana-loki                       3.7.3 -> 3.7.6
 - linux                              6.18.38 -> 6.18.46
 - linux-firmware                     20260622-zstd -> 20260810-zstd
 - lubelogger                         1.7.0 -> 1.7.1
 - mesa                               26.1.4 -> 26.1.8
 - moby                               29.6.1 -> 29.7.2
 - nano                               9.1 -> 9.2
 - nix                                2.34.7 -> 2.34.8
 - nodejs                             24.16.0 -> 24.19.0
 - ntfy-sh                            2.23.0 -> 2.26.0
 - openssh                            10.3p1 -> 10.5p1
 - openssl                            3.6.2 -> 3.6.3
 - pds                                0.4.5009 -> 0.4.5027
 - postgresql-and-plugins             17.10 -> 17.11
 - python3                            3.13.13, 3.14.4 -> 3.13.15, 3.14.7
 - qemu-host-cpu-only                 10.2.2-ga -> 10.2.4-ga
 - rclone                             1.74.4 -> 1.75.0
 - tailscale                          1.98.5 -> 1.98.10
 - traefik                            3.7.6 -> 3.7.10
 - tzdata                             2026b -> 2026c


## [0.7.2] - 2026-08-18

### Changes

- feat(france): kosync-dotnet -> koreader-sync
- feat(nixos): module for running koreader-sync
- feat(pkgs): init koreader-sync -> 0.2.3


## [0.7.1] - 2026-07-22

### Changes

- feat: update authentik 2026.5.5 -> 2026.5.6
- feat: linkwarden increase file upload limits
- feat: linkwarden configure for leaner setup
- feat: update linkwarden 2.14 -> 2.15.1


## [0.7.0] - 2026-07-17

### Changes

- feat: authentik 2026.2.3 -> 2026.5.5
- feat(france): update lubelogger 1.6.8 -> 1.7.0
- feat: lubelogger 1.6.5 -> 1.7.0
- feat: limit journald's log retention
- feat: limit Loki's log retention
- feat: update to NixOS 26.05
- compat(lix): fix broken-string-escape warnings


## [0.6.2] - 2026-05-21

### Added

- (justfile): deployrs, optionally with only one host

### Changed

- update den library
- (dockeras): remove pre-dendritic NixOS module
- add extra debugging code around `dockeras`
- standardize the trace messages
- lubelogger: 1.6.3 -> 1.6.5
- (lubelogger): automatic account creation for OIDC users
- update sources
- authentik 2026.2.2 -> 2026.2.3

### Fixed

- `dockeras` username wasn't fully DRY
- (attic): triple the chunk sizes
- (france): disable crowdsec


## [0.6.1] - 2026-04-08

### Changed

- feat(caddy): build caddy with Go 1.26
- feat(caddy): update plugins


## [0.6.0] - 2026-04-08

### Added

- build: justfile `deployrs` task to deploy all hosts using deploy-rs
- build: justfile `validate` tasks to run `nix flake check --all-systems -L`

### Changed

- lubelogger: 1.6.1 -> 1.6.3
- caddy: 2.10.2 -> 2.11.2
- traefik: 3.6.7 -> 3.6.13
- authentik: 2026.2.1 -> 2026.2.2
- chore: update sources

### Fixed

- SSH is not restarted after certificate renewal
- SSH certificates on france do not use default principals


## [0.5.0] - 2026-03-20

### Added

- everything that has gone before


## [Sections]

### Added

### Changed

### Removed

### Deprecated

### Fixed

### Security
