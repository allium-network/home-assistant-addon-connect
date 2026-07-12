# Allium Connect (Home Node) — Home Assistant Add-on Repository

> **Your home, anywhere — without opening a single port.**

This repository contains the **Allium Connect (Home Node)** add-on: it registers
your Home Assistant server as a device on your [allium.network](https://allium.network)
account, so you can reach Home Assistant — and anything else on your LAN — from
your phone or laptop, from anywhere, with **no port-forwarding, no DDNS, no
reverse proxy**.

## How it works

- Install the add-on and paste a **connect token** from your dashboard
  (allium.network → **Devices → add a headless node**; the token is shown once).
- The add-on registers a WireGuard device on your account and keeps an
  end-to-end-encrypted tunnel available to your other Allium devices.
- Connections go **direct, peer-to-peer** whenever possible. When two networks
  can't link directly, traffic falls back through a relay that only ever
  forwards **sealed ciphertext** — zero-knowledge by design: neither the relay
  operator nor Allium can read it.
- Register your services (Home Assistant on 8123, Plex, your NAS, a printer…)
  in the dashboard and open them from any of your devices as if you were home.

## Security in one paragraph

Keys are generated on your devices and never leave them. Every tunnel is
end-to-end encrypted (WireGuard). There are no inbound ports: everything is
outbound-only, so your router and firewall stay closed. The relay tier is
zero-knowledge — it moves opaque ciphertext it cannot decrypt. Your device
identity lives in the add-on's private data volume on your own hardware.

## This is NOT the "Allium Mesh" add-on

Both add-ons exist, and they do different jobs:

| | **Allium Connect (Home Node)** — this repo | **[Allium Mesh](../home-assistant-addon/allium-mesh/DOCS.md)** — anonymous |
|---|---|---|
| Account | Yes — registers on your allium.network account | No account, fully anonymous |
| Main job | Reach HA + your LAN from anywhere (fast WireGuard tunnels, named services, device list) | Contribute a Tor Snowflake proxy; free `.onion` remote access in return |
| Remote access | Native apps, direct P2P speed | Tor Browser via a `.onion` address |
| Contribution | Optional (mesh relay, Snowflake, Tor middle node) | The point of the add-on |

Run one or both — they don't conflict. If you only want to help censored users
and don't want an account, use Allium Mesh. If you want "my home, from
anywhere, no open ports", this add-on is the one.

## Installation

1. In Home Assistant: **Settings → Add-ons → Add-on Store → ⋮ → Repositories**,
   add this repository's URL.
2. Install **Allium Connect (Home Node)**.
3. Paste your connect token into the add-on configuration and start it.

Full option reference, privileges and troubleshooting: see the add-on's
[DOCS.md](allium-connect/DOCS.md).
