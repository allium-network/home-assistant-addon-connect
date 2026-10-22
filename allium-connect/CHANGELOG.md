# Changelog

## 0.3.0
- **No more token to copy.** The add-on's page shows a short code; approve it on
  allium.network (sign in or create a free account) and the add-on links itself and
  restarts. Pasting a token still works if you prefer it.
- **Home Assistant is added to your account for you** the first time the add-on
  connects, so the address for the Home Assistant app appears without a visit to the
  dashboard. If you delete it, it stays deleted.
- If your token stops working, the page shows a new code to link again.
- A token you pasted earlier no longer overrides a newer link.

## 0.2.1
- **The next step now shows up in Home Assistant's notifications.** Once the
  add-on is connected, a notification tells you the exact External URL to enter in
  the Home Assistant app. If something needs you (no token yet, a token that stopped
  working, Home Assistant not reachable), the notification says what to do. There is
  only ever one Allium notification; it is replaced when the next step changes, and
  once you dismiss it, it stays away until there is something new.
- **Fixed: setting "Where your services run" for another machine could cut off Home
  Assistant itself.** Home Assistant is now always found on this box, whatever that
  option says (it is renamed "Where your other services run").
- **Fixed: the status page kept saying "Connected" after the add-on stopped.** It now
  warns when it can't reach the add-on.
- **Fixed: right after a start, the page asked you to add Home Assistant even when you
  already had.** That card now waits until the add-on is connected.
- **Fixed: "Use your home internet when away" showed Off when it was on but could not
  start.** It now says "Not available now".
- Snowflake says "Not running" (with the reason) when your safety settings don't allow
  sharing on this connection, instead of "Starting" forever.
- The add-on no longer asks for Supervisor API access; it didn't need it.
- For the notifications the add-on now asks for Home Assistant API access. It uses it only to
  create or remove that one notification; it never changes your Home Assistant
  settings.

## 0.2.0
- **New: the add-on has its own page** (Open Web UI, or Allium Connect in the
  sidebar). It shows whether you're connected, the exact External URL to paste into
  the Home Assistant app (with a Copy button), whether this box can reach each
  service you added, your devices, and what you're sharing. When something is
  wrong, it says what to do. It is read-only: settings stay in the Configuration tab.
- **Simpler settings.** The Configuration tab now shows four options: connect token,
  device name, "Use your home internet when away", and "Help censored users (Tor
  Snowflake)". The rest moved under "Show unused optional configuration options",
  with plain descriptions. Anything you already set is kept.
- **Home Assistant is found automatically.** You no longer need to type your Home
  Assistant IP into "Where your services run".
- **First start without a token no longer fails.** The add-on stays up and its page
  explains where to get a token, instead of stopping with an error in the log.
- "Contribute on Home Network" turned out to change only a status label, so it moved
  to the advanced options and says so. "Relay for other Allium users" now explains
  that it only helps when this box is reachable from the internet.

## 0.1.13
- **Fix: "Contribute Relay Capacity" off now really means off.** In 0.1.10 the switch
  was only passed to the node when it was on; left unset, the node defaulted to
  forwarding relay traffic for other peers. Off is now sent explicitly.
- **Reliability: reach your home services from anywhere, consistently.** The home
  node now converges on the same relay as your other devices instead of picking one
  at random, so reaching Home Assistant / Plex / your NAS from a phone or laptop on
  a restrictive network no longer intermittently fails to connect.
- Built on the current Allium Connect engine, including its latest security updates.
- The node no longer runs its own update check — the Supervisor delivers add-on
  updates.

## 0.1.10
- Snowflake sharing stats + monthly-cap tally now persist across restarts/updates;
  in-panel cap control and Stop/Resume.
