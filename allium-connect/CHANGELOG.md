# Changelog

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
