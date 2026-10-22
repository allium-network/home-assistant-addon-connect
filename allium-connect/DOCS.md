# Allium Connect (Home Node)

Reach Home Assistant, and anything else on your home network, from your phone
or laptop, wherever you are. No port forwarding, no DynDNS, no reverse proxy.

Your phone or laptop runs the Allium Connect app; this add-on is the home end.
The two connect with an end-to-end-encrypted WireGuard tunnel: directly when
possible, through an Allium relay when not. A relay only passes on sealed,
encrypted traffic that neither it nor Allium can read.

## Setup (about 5 minutes)

1. **Get a connect token.** Sign in at [allium.network](https://allium.network),
   then go to **Dashboard → Network → Add a headless device**. Copy the token: it
   is shown only once.
2. **Paste it.** In this add-on's **Configuration** tab, paste it under
   **Connect token**, click **Save**, then **Start** (or **Restart**) the add-on.
3. **Tell Allium where Home Assistant is.** In the dashboard: **Services → Add
   service**, pick this device (`home-assistant`), then **Home Assistant**, port
   **8123**.
4. **Set up the Home Assistant app.** Open the add-on's page (**Open Web UI**, or
   **Allium Connect** in the sidebar). It shows the exact **External URL** to paste
   into the app: *Settings → Companion app → your server → External URL*. Keep your
   Internal URL as it is and list your home Wi-Fi under *Home network*.
5. **Test it** with Wi-Fi off on your phone and Allium Connect switched on.

The add-on's page tells you at every step what is working and what is not.

## The add-on's page

Open it with **Open Web UI** on the add-on, or turn on **Show in sidebar**. It
shows:

- whether this box is **connected**, and if not, exactly what to do;
- the **External URL** for the Home Assistant app, with a Copy button, and
  whether this box can reach Home Assistant;
- other services you added on this box, and whether each one answers;
- your **devices**: online or offline, direct or via a relay;
- your **choices** (below) and how much was shared this month.

The page only shows things. All settings are changed in the **Configuration** tab,
and the page has a button to go there.

## Your choices

The Configuration tab shows four options:

| Option | Default | What it does |
|---|---|---|
| **Connect token** | empty | Links the add-on to your Allium account. Needed once; the add-on remembers it. |
| **Device name** | `home-assistant` | How this box is named in your Allium devices. |
| **Use your home internet when away** | off | Your phone and laptop can send all their internet traffic through your home connection, as if you were home. Only your own devices can use it. Not anonymity: your internet provider still sees the traffic. |
| **Help censored users (Tor Snowflake)** | off | Lends a little bandwidth so people in countries that block the internet can reach Tor. Your IP is not listed publicly, and nobody's traffic leaves the internet from your home. Stops at your monthly data cap. |

### Advanced options

These are hidden until you click **Show unused optional configuration options**.
Most people never need them.

| Option | Default | What it does |
|---|---|---|
| **Open .onion sites through home** | off | Also sends `.onion` addresses through a Tor client on this box, so your devices can open onion sites without a Tor app. Turns on the home internet option above. Your internet provider then sees Tor connections from your home. |
| **Relay for other Allium users** | off | Forwards other accounts' encrypted traffic when their devices can't connect directly. Only works if this box is reachable from the internet. A normal home with no open ports is not, so for most people this does nothing. |
| **Run a Tor relay** | off | Runs a public Tor middle relay. Your home IP appears in Tor's public relay list, and you must map port `9001/tcp` in the Network section. |
| **Host my public websites here** | on | Serves your account's public domains (and `.onion` publishes) from this box. Turn it off if another always-on device, like a NAS, is where your websites actually run. |
| **Where your services run** | empty | Leave empty: Home Assistant on this box is found automatically. Fill in an IP address only if the page says a service you added can't be reached because it runs on another machine. |
| **Show sharing as active at home** | on | Kept for older setups. It only changes a status label in the log; it does not switch any sharing on or off. |

### Monthly data cap and speed limit

The cap and speed limit for sharing are set in your **allium.network dashboard**
(the Contribution card), not here. They apply to all your devices together. When
the monthly cap is used up, sharing pauses until the next month; your own remote
access keeps working. The add-on picks up changes within about 20 seconds.

## Updates

Home Assistant offers new versions of this add-on like any other: **Settings →
Add-ons → Allium Connect → Update**. Your device identity and choices are kept.
Turn on **Auto update** on the add-on's page if you want updates installed for
you.

## Privileges this add-on needs

- **`/dev/net/tun` + `NET_ADMIN`**: the tunnel is a virtual network interface;
  creating it and its routes needs both. They are granted automatically.
- **Read-only Supervisor access**: used once at start-up to learn the add-on's own
  name, so the page can link to its Configuration tab.
- **Ingress**: the page is served through Home Assistant's own login. Nothing else
  can open it: not your other devices on the mesh, and not other add-ons.
- No access to Home Assistant's data or API.

## Security

- **End-to-end encrypted**: keys are made on your devices and never leave them.
- **Relays can't read your traffic**: they pass on sealed ciphertext.
- **No open ports**: every connection goes out from your home; your router stays
  closed.
- The device identity (connect token, WireGuard key, signing key) lives in the
  add-on's private data and is included in Home Assistant backups.

## Stored data

Kept in `/data/allium-connect/`, across restarts and updates:

- `connect-token`: the device's account token
- `wg.key`: WireGuard private key (keeps the same mesh address)
- `identity.key`: Ed25519 signing key
- `preferences.json`: saved choices

Uninstalling the add-on deletes these. A reinstall then shows up as a new device
with a new mesh address and needs a new connect token.

## Troubleshooting

The add-on's page names the problem. In short:

- **"One step left: link your Allium account"**: no connect token yet. Follow the
  steps on the page.
- **"Your connect token no longer works"**: it was revoked or expired. Make a new
  one (Dashboard → Network → Add a headless device), paste it, restart.
- **"This box can't reach Home Assistant"**: put the IP address of the machine
  running Home Assistant in **Where your services run**, then restart.
- **"Connected, but traffic can't flow"**: the network interface could not be
  created. Reinstall the add-on from the Allium repository without changes.
- **The External URL doesn't show**: add Home Assistant as a service in the
  dashboard (Setup, step 3). It appears within a few minutes.
