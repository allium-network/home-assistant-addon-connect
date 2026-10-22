#!/usr/bin/env bash
set -euo pipefail

# Source bashio if available (HA add-on environment).
if [ -f /usr/lib/bashio.sh ]; then
    # shellcheck source=/dev/null
    source /usr/lib/bashio.sh
fi

# ── Read configuration from HA options.json ──────────────────────────────
# Only connect_token, device_name, advertise_exit and snowflake always exist.
# The advanced options are optional (`?` in config.yaml) and are simply absent
# until someone sets them, so every read below carries its default.
CONFIG_PATH="/data/options.json"

if [ -f "$CONFIG_PATH" ]; then
    CONNECT_TOKEN=$(jq -r '.connect_token // ""' "$CONFIG_PATH")
    DEVICE_NAME=$(jq -r '.device_name // "home-assistant"' "$CONFIG_PATH")
    # NOTE: jq's // treats an explicit `false` as empty, so a plain
    # `.contribute_home // true` could never be turned off — spell it out.
    CONTRIBUTE_HOME=$(jq -r 'if .contribute_home == false then "false" else "true" end' "$CONFIG_PATH")
    SNOWFLAKE=$(jq -r '.snowflake // false' "$CONFIG_PATH")
    MIDDLE_NODE=$(jq -r '.middle_node // false' "$CONFIG_PATH")
    RELAY_CONTRIBUTE=$(jq -r '.relay_contribute // false' "$CONFIG_PATH")
    ADVERTISE_EXIT=$(jq -r '.advertise_exit // false' "$CONFIG_PATH")
    EXIT_TOR=$(jq -r '.exit_tor // false' "$CONFIG_PATH")
    # jq's // treats an explicit `false` as empty — spell it out (see contribute_home).
    HOST_DOMAINS=$(jq -r 'if .host_domains == false then "false" else "true" end' "$CONFIG_PATH")
    SERVICE_UPSTREAM=$(jq -r '.service_upstream // ""' "$CONFIG_PATH")
else
    CONNECT_TOKEN=""
    DEVICE_NAME="home-assistant"
    CONTRIBUTE_HOME=true
    SNOWFLAKE=false
    MIDDLE_NODE=false
    RELAY_CONTRIBUTE=false
    ADVERTISE_EXIT=false
    EXIT_TOR=false
    HOST_DOMAINS=true
    SERVICE_UPSTREAM=""
fi

# ── State dir (device identity: connect token, WG key, identity key) ─────
export ALLIUM_HEADLESS=1
export ALLIUM_STATE_DIR="${ALLIUM_STATE_DIR:-/data/allium-connect}"
mkdir -p "$ALLIUM_STATE_DIR"
chmod 700 "$ALLIUM_STATE_DIR"

# ── Status page (HA sidebar → Allium Connect) ─────────────────────────────
# Read-only, on the ingress port, answering only the Supervisor's ingress proxy
# (so it sits behind Home Assistant's own login — never mesh peers or other
# add-ons). It also carries the first-start instructions when no token is set.
export ALLIUM_STATUS_PANEL_ADDR=":8099"
export ALLIUM_STATUS_PANEL_ALLOW="172.30.32.2"
# The page links to this add-on's Configuration tab, which needs the real slug
# (a repository install is "<repo-hash>_allium-connect").
if [ -n "${SUPERVISOR_TOKEN:-}" ]; then
    SLUG=$(curl -fsS --max-time 5 -H "Authorization: Bearer ${SUPERVISOR_TOKEN}" \
        http://supervisor/addons/self/info 2>/dev/null | jq -r '.data.slug // empty' || true)
    if [ -n "$SLUG" ]; then
        export ALLIUM_HA_ADDON_SLUG="$SLUG"
    fi
fi

# ── Connect token ─────────────────────────────────────────────────────────
# The token comes from the dashboard (allium.network → Network → Add a headless
# device) and is shown once. The binary persists it to $ALLIUM_STATE_DIR/connect-token
# on first run, so it keeps working even if the option is later cleared. With no
# token at all the node does not exit: it keeps the status page up, which tells
# the user where to get one.
if [ -n "$CONNECT_TOKEN" ]; then
    export ALLIUM_CONNECT_TOKEN="$CONNECT_TOKEN"
elif [ ! -f "${ALLIUM_STATE_DIR}/connect-token" ]; then
    echo "[allium-connect] No connect token yet. Get one at https://allium.network" >&2
    echo "[allium-connect] (Dashboard → Network → Add a headless device), paste it into the" >&2
    echo "[allium-connect] 'Connect token' option, then restart. The add-on's page explains the steps." >&2
fi

# ── Device name shown in the dashboard ────────────────────────────────────
# Containers have a random hostname, so always pass the explicit name.
export ALLIUM_DEVICE_NAME="$DEVICE_NAME"

# ── TUN device (WireGuard data path) ─────────────────────────────────────
# config.yaml declares /dev/net/tun + NET_ADMIN; create the node defensively in
# case the Supervisor mapped the device dir but not the node. Failure is
# non-fatal — the binary detects the missing TUN and degrades gracefully
# (registers + contributes, but cannot route mesh traffic).
if [ ! -c /dev/net/tun ]; then
    mkdir -p /dev/net
    if ! mknod /dev/net/tun c 10 200 2>/dev/null; then
        echo "[allium-connect] WARNING: /dev/net/tun unavailable — mesh routing disabled" >&2
    fi
fi

# ── Contribution toggles ──────────────────────────────────────────────────
# The HA options form is the source of truth: export explicit true/false so the
# add-on config always overrides any previously persisted preference.
#
# contribute_home: a home node LIVES on the home network — without this the
# generic "don't relay on your home network" laptop heuristic would keep it in
# standby forever. Forwards only sealed E2E ciphertext, within safety limits.
export ALLIUM_CONTRIBUTE_HOME="$CONTRIBUTE_HOME"
# snowflake / middle_node: strictly opt-in Tor contributions (default OFF) —
# your machine becomes outward-facing Tor infrastructure. Middle-node needs the
# 9001/tcp port mapping enabled in the add-on's network settings.
export ALLIUM_SNOWFLAKE="$SNOWFLAKE"
export ALLIUM_MIDDLENODE="$MIDDLE_NODE"

# relay_contribute (default OFF): mesh relay forwarder — share spare bandwidth
# so other peers' devices can connect when they can't link directly. Always
# exported EXPLICITLY, true or false: when the variable is unset a headless
# node defaults to contributing, so exporting only on opt-in made OFF a no-op.
if [ "$RELAY_CONTRIBUTE" = "true" ]; then
    export ALLIUM_MESH_RELAY_CONTRIBUTE="true"
else
    export ALLIUM_MESH_RELAY_CONTRIBUTE="false"
fi

# ── iptables backend selection ────────────────────────────────────────────
# Alpine's iptables defaults to the nf_tables backend; on host kernels without
# nf_tables (seen on some NAS host kernels) every NAT/forward rule fails and the
# node silently withdraws its exit capability. Probe the default backend once
# and fall back to iptables-legacy when the kernel can't do nf_tables.
# /usr/local/sbin precedes /sbin in PATH, so the binary's `iptables` calls pick
# up the override.
if ! iptables -t nat -nL > /dev/null 2>&1; then
    if command -v iptables-legacy > /dev/null 2>&1 && iptables-legacy -t nat -nL > /dev/null 2>&1; then
        echo "[allium-connect] kernel lacks nf_tables — using iptables-legacy backend"
        mkdir -p /usr/local/sbin
        ln -sf "$(command -v iptables-legacy)" /usr/local/sbin/iptables
        if command -v ip6tables-legacy > /dev/null 2>&1; then
            ln -sf "$(command -v ip6tables-legacy)" /usr/local/sbin/ip6tables
        fi
    else
        echo "[allium-connect] WARNING: no working iptables backend — exit/subnet-router modes unavailable" >&2
    fi
fi

# ── Home gateway: internet exit + .onion detour (opt-in, default OFF) ──────
# advertise_exit: this node carries YOUR account's default-route traffic — your
# phone/laptop's whole internet exits from this home IP (Home exit mode). It is
# NOT anonymity (your ISP still sees the traffic); it makes you "appear at home".
# exit_tor: additionally detour .onion (dark web) through a local Tor client, so
# clients reach onion services with no Tor app of their own (your ISP then sees
# Tor connections). exit_tor implies the exit. Both install iptables forwarding/
# NAT (NET_ADMIN, already declared) and need ip_forward — enabled by the binary.
if [ "$EXIT_TOR" = "true" ]; then
    export ALLIUM_EXIT_TOR="1"
    export ALLIUM_ADVERTISE_EXIT="1"
elif [ "$ADVERTISE_EXIT" = "true" ]; then
    export ALLIUM_ADVERTISE_EXIT="1"
fi

# ── Public domain hosting (default ON) ────────────────────────────────────
# host_domains=false sets ALLIUM_INGRESS_HOSTING=0: this node stops serving the
# account's public ingress domains (and .onion publishes). Use when another
# always-on node (e.g. a NAS home node) is the real host — otherwise this box
# can win the per-domain lease and serve nothing.
if [ "$HOST_DOMAINS" = "false" ]; then
    export ALLIUM_INGRESS_HOSTING="0"
fi

# ── Where registered services live ────────────────────────────────────────
# service_upstream set: every service is on that host (the user's explicit
# answer wins, including for Home Assistant itself).
# Not set: Home Assistant (8123) is reached by its Supervisor DNS name,
# `homeassistant`, which resolves to Core from inside any add-on; every other
# port keeps the binary's auto-detect. The status page shows, per service,
# whether this box can actually reach it, and says what to set if not.
if [ -n "$SERVICE_UPSTREAM" ]; then
    export ALLIUM_SERVICE_UPSTREAM="$SERVICE_UPSTREAM"
elif [ -n "${SUPERVISOR_TOKEN:-}" ] && [ -z "${ALLIUM_SERVICE_UPSTREAMS:-}" ]; then
    export ALLIUM_SERVICE_UPSTREAMS="8123=homeassistant"
fi

# ── Start the headless home node ──────────────────────────────────────────
echo "[allium-connect] starting headless home node (device: ${DEVICE_NAME})"
exec /usr/local/bin/allium-connect --headless
