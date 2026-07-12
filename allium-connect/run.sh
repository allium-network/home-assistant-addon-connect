#!/usr/bin/env bash
set -euo pipefail

# Source bashio if available (HA add-on environment).
if [ -f /usr/lib/bashio.sh ]; then
    # shellcheck source=/dev/null
    source /usr/lib/bashio.sh
fi

# ── Read configuration from HA options.json ──────────────────────────────
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
    SERVICE_UPSTREAM=""
fi

# ── State dir (device identity: connect token, WG key, identity key) ─────
export ALLIUM_HEADLESS=1
export ALLIUM_STATE_DIR="${ALLIUM_STATE_DIR:-/data/allium-connect}"
mkdir -p "$ALLIUM_STATE_DIR"
chmod 700 "$ALLIUM_STATE_DIR"

# ── Connect token ─────────────────────────────────────────────────────────
# The token comes from the dashboard (allium.network → Devices → add a headless
# node) and is shown once. The binary persists it to $ALLIUM_STATE_DIR/connect-token
# on first run, so it keeps working even if the option is later cleared.
if [ -n "$CONNECT_TOKEN" ]; then
    export ALLIUM_CONNECT_TOKEN="$CONNECT_TOKEN"
elif [ ! -f "${ALLIUM_STATE_DIR}/connect-token" ]; then
    echo "[allium-connect] ERROR: no connect token configured." >&2
    echo "[allium-connect] Generate one at https://allium.network (Devices → add a headless node)" >&2
    echo "[allium-connect] and paste it into the add-on's 'Connect Token' option, then restart." >&2
    exit 1
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
# so other peers' devices can connect when they can't link directly. Sealed
# ciphertext only. Exported solely on explicit opt-in (mirrors the allium-mesh
# add-on's pattern: unset = the agent defaults to NOT contributing).
if [ "$RELAY_CONTRIBUTE" = "true" ]; then
    export ALLIUM_MESH_RELAY_CONTRIBUTE="true"
fi

# ── iptables backend selection ────────────────────────────────────────────
# Alpine's iptables defaults to the nf_tables backend; on host kernels without
# nf_tables (seen live on Synology DSM) every NAT/forward rule fails and the
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

# ── Service proxy upstream override (advanced) ────────────────────────────
# Where this node's registered services actually live. Unset = auto-detect
# (host gateway — correct on Home Assistant OS, where HA listens on the host).
if [ -n "$SERVICE_UPSTREAM" ]; then
    export ALLIUM_SERVICE_UPSTREAM="$SERVICE_UPSTREAM"
fi

# ── Start the headless home node ──────────────────────────────────────────
echo "[allium-connect] starting headless home node (device: ${DEVICE_NAME})"
exec /usr/local/bin/allium-connect --headless
