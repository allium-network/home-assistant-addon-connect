# Allium Connect (Home Node) — Home Assistant Add-on Repository

> **Your home, anywhere, without opening a single port.**

This add-on adds your Home Assistant box to your [allium.network](https://allium.network)
account, so you can reach Home Assistant, and anything else on your home network,
from your phone or laptop wherever you are. No port forwarding, no DynDNS, no
reverse proxy.

## Install

1. In Home Assistant: **Settings → Add-ons → Add-on Store → ⋮ → Repositories**,
   add `https://github.com/allium-network/home-assistant-addon-connect`.
2. Install **Allium Connect (Home Node)** and start it.
3. Open the add-on's page (**Open Web UI**). It walks you through the rest: get a
   connect token at **Dashboard → Network → Add a headless device**, paste it in the
   **Configuration** tab, add Home Assistant as a service, and copy the address for
   the Home Assistant app.

Updates arrive through Home Assistant like any other add-on.

## How it works

- Your phone or laptop runs the Allium Connect app; this add-on is the home end.
- They connect **directly, peer-to-peer** whenever possible. When two networks
  can't link directly, traffic goes through a relay that only passes on **sealed
  ciphertext**: neither the relay nor Allium can read it.
- Keys are made on your devices and never leave them. Every connection goes out
  from your home, so your router stays closed.

## Choices

Four everyday options: the connect token, a device name, **Use your home internet
when away**, and **Help censored users (Tor Snowflake)**. Everything else is under
the advanced options and off unless you need it. Full reference: [DOCS.md](allium-connect/DOCS.md).

## Coming from "Allium Mesh"?

The Allium Mesh add-on is retired. This add-on replaces it: faster native access
instead of Tor Browser, and the same Snowflake proxy if you want to keep helping.
Install this one, check that you can reach Home Assistant through it, then
uninstall Allium Mesh.
