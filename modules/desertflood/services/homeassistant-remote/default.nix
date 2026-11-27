# SPDX-FileCopyrightText: 2025 Joe Martin <joe@desertflood.com>
# SPDX-License-Identifier: BlueOak-1.0.0
_: {
  df.services.homeassistant-remote = { host, ... }: {
    traefik-apps = {
      homeassistant = {
        rule = "Host(`house.thosemartins.family`)";
        url = "http://${host.desertflood.globals.tailscaleIPs.homeassistant}:80";
        middlewares = "chain-no-auth@file";
      };
    };
  };
}
