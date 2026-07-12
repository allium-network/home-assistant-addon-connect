# Allium Connect (Home Node) — Home Assistant Add-on

## What it does

This add-on turns your Home Assistant server into an **Allium Connect home
node**: a device registered on your allium.network account that lets you reach
Home Assistant — and any other service on your LAN — from anywhere, **without
opening a single port** on your router.

Your phone or laptop runs the Allium Connect app; this add-on runs the home
end. The two ends build an end-to-end-encrypted WireGuard tunnel through the
Allium mesh (direct peer-to-peer when possible, through a relay when not).
Relays only ever forward sealed ciphertext — neither the relay operator nor
Allium can read your traffic.

**This is different from the "Allium Mesh" add-on**, which is the anonymous,
account-free Tor Snowflake proxy + .onion access add-on. See the repository
README for a comparison — you can run both side by side.

## Setup

1. Create an account at [allium.network](https://allium.network) and open the
   dashboard.
2. Go to **Devices → add a headless node** and generate a **connect token**
   (it is shown once — copy it right away).
3. Install this add-on, paste the token into the **Connect Token** option,
   optionally change the **Device Name**, and start the add-on.
4. The node appears in your dashboard device list within a few seconds. Add
   your services (e.g. Home Assistant on port 8123) from the dashboard; they
   become reachable from your other Allium devices immediately.

The token is persisted in the add-on's private data folder after the first
start, so you may clear the option field afterwards if you prefer.

## Configuration

| Option | Default | Description |
|--------|---------|-------------|
| `connect_token` | *(empty)* | Token from the dashboard (Devices → add a headless node). Required on first start. |
| `device_name` | `home-assistant` | Name shown in your dashboard / device list. |
| `contribute_home` | `true` | Forward other peers' sealed mesh traffic from this always-on node. |
| `snowflake` | `false` | Also run a Tor Snowflake proxy (helps censored users). |
| `middle_node` | `false` | Run a Tor middle relay (public relay list, needs port 9001/tcp mapped). |
| `relay_contribute` | `false` | Share spare relay capacity for peers that can't connect directly. |
| `advertise_exit` | `false` | Become your account's "Home" internet exit — your devices' traffic leaves from your home IP. Not anonymity; same-account only. |
| `exit_tor` | `false` | Also detour .onion addresses through a local Tor client (implies the exit). Your ISP then sees Tor connections. |
| `service_upstream` | *(auto)* | Advanced: host/IP where registered services listen. Leave empty on Home Assistant OS. |

## Contribution limits (speed + monthly data cap)

Contribution caps are managed from your **allium.network dashboard** (the
Contribution card), not from add-on options — they are account-wide and shared
with your other devices, exactly like the desktop app:

- **Speed cap (Mbps)** — limits the Tor relay's bandwidth (applied to the
  relay's configuration when the middle node runs).
- **Monthly data cap (GB)** — the built-in safety governor counts contributed
  bytes and pauses all contribution (mesh relay, Snowflake, Tor) when the
  monthly budget is used up; your own remote access keeps working. Contribution
  resumes automatically when the month resets.

The node picks up dashboard changes within about 20 seconds; the current caps
are shown in the add-on log's periodic status line.

## Privileges this add-on needs

- **`/dev/net/tun` + `NET_ADMIN`** — the WireGuard tunnel is a virtual network
  interface; creating it and installing its routes requires the TUN device and
  the NET_ADMIN capability. Both are declared in the add-on manifest and
  granted automatically by the Supervisor. Without them the node still
  registers and heartbeats, but cannot route mesh traffic.
- No Home Assistant API access, no ingress, no other host access.

## Security

- **End-to-end encrypted**: WireGuard keys are generated on your devices; the
  tunnel is sealed between them.
- **Zero-knowledge relays**: when two devices can't connect directly, traffic
  is forwarded as opaque ciphertext by a relay that cannot decrypt it.
- **No open ports**: all connections are outbound; your router config is
  untouched.
- The device identity (connect token, WireGuard key, signing key) lives in the
  add-on's private `/data` volume and never leaves your machine.

## Contribution toggles (all optional)

- **Contribute on Home Network** (default on): an always-on home node is the
  ideal mesh relay — it forwards only sealed ciphertext, within the built-in
  safety limits. Turn it off for a connect-only node.
- **Tor Snowflake / Tor Middle Node** (default off): opt-in Tor contributions.
  Middle-node mode puts your IP in Tor's public relay list and requires mapping
  port `9001/tcp` in the add-on's network settings — read up before enabling.
- **Contribute Relay Capacity** (default off): serve as a fallback relay for
  other Allium users' devices.

## Persistent data

Stored in `/data/allium-connect/` and kept across restarts and updates:

- `connect-token` — your device's account token
- `wg.key` — WireGuard private key (stable mesh IP / device identity)
- `identity.key` — Ed25519 signing key (relay authentication)
- `preferences.json` — sticky toggles

Deleting the add-on's data resets the device identity: the node will register
as a brand-new device with a new mesh IP and will need a fresh connect token.

## Troubleshooting

- **"no connect token"** in the log — set the `connect_token` option (see Setup).
- **Services unreachable** but the device shows online — set `service_upstream`
  to the IP of the machine actually running the service.
- **"insufficient privileges for the network interface"** — the Supervisor did
  not grant the TUN device; make sure you installed this add-on from its
  repository unmodified (the manifest declares `/dev/net/tun` + `NET_ADMIN`).
