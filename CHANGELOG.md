# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html)
(as much as possible for something that is a collection of system
configurations).

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
