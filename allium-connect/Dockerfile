# Pre-built binary — cross-compiled outside the Supervisor, same pattern as the
# allium-mesh add-on: the HA Supervisor's Docker daemon cancels builds that pull
# the golang builder image (resource/timeout ceiling), so the headless
# allium-connect binary is built on the release machine and COPY'd in.
#
# The Supervisor passes BUILD_ARCH (amd64 | aarch64) as a build arg, matching
# the `arch:` list in config.yaml. The published add-on repo carries one binary
# per arch (allium-connect-amd64 / allium-connect-aarch64), produced by
# Mesh/scripts/publish-ha-addons.sh — the -tags headless build links no
# tray/GTK, so CGO is off and the result is fully static.
FROM alpine:3.20
ARG BUILD_ARCH=amd64
ARG BUILD_VERSION
LABEL io.hass.version="${BUILD_VERSION}"

# iproute2: WireGuard route/address management on the TUN interface.
# iptables: forwarding + NAT chains for the subnet router (advertise_routes) and
#      the internet exit (advertise_exit) — both opt-in. run.sh falls back to
#      the legacy backend at startup when the host kernel lacks nf_tables
#      (same failure mode as the Synology home node — see run.sh).
# tor: the Tor middle-node contribution (middle_node) AND the home-gateway
#      .onion detour (exit_tor). The mesh, relay and Snowflake features work
#      without it, but bundling makes the toggles work out of the box.
# bash/jq/curl: run.sh (bashio is not installed; run.sh guards its source and
#      reads all config with jq, mirroring the allium-mesh add-on).
RUN apk add --no-cache bash curl jq ca-certificates iproute2 iptables iptables-legacy tor

COPY allium-connect-${BUILD_ARCH} /usr/local/bin/allium-connect
COPY run.sh /run.sh
RUN chmod +x /usr/local/bin/allium-connect /run.sh

# /data is the add-on's persistent volume: the connect token, WireGuard key and
# Ed25519 identity key live under /data/allium-connect so the node keeps ONE
# stable device identity / mesh IP across restarts and updates.
ENV ALLIUM_HEADLESS=1 \
    ALLIUM_STATE_DIR=/data/allium-connect

# HA add-ons conventionally run as root inside the container — the container is
# the security boundary, and the TUN device + /data mount require root anyway.
ENTRYPOINT ["/run.sh"]
