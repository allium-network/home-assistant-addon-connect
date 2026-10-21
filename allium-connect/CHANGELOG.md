# Changelog

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
