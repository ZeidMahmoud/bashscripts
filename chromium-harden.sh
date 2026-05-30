#!/bin/sh
# chromium-harden.sh - Make Chromium robust, secure, and powerful on Void/Ageless musl.
# Idempotent: safe to re-run. Run as: sudo bash chromium-harden.sh
# Writer : Zeid Mahmoud
set -e

if [ "$(id -u)" -ne 0 ]; then
    echo "Re-running with sudo..."
    exec sudo -E sh "$0" "$@"
fi

USER_NAME=${SUDO_USER:-zeid}
USER_HOME=$(getent passwd "$USER_NAME" | cut -d: -f6)

echo "==> [1/7] Installing packages"
xbps-install -Sy zramen intel-video-accel libva-utils

echo "==> [2/7] Writing kernel tuning (sysctl)"
cat > /etc/sysctl.d/99-chromium.conf <<'EOF'
# Chromium robustness - keep desktop responsive under memory pressure
vm.swappiness=180
vm.watermark_boost_factor=0
vm.watermark_scale_factor=125
vm.page-cluster=0
kernel.sched_autogroup_enabled=1
EOF
sysctl --system >/dev/null

echo "==> [3/7] Configuring zramen (75% RAM, zstd)"
cat > /etc/default/zramen <<'EOF'
SIZE=75
ALGO=zstd
PRIORITY=100
EOF

echo "==> [4/7] Enabling zramen service"
[ -L /var/service/zramen ] || ln -s /etc/sv/zramen /var/service/zramen

echo "==> [5/7] Installing chromium-cgroup runit service"
mkdir -p /etc/sv/chromium-cgroup
cat > /etc/sv/chromium-cgroup/run <<EOF
#!/bin/sh
# Sets up cgroup v2 limits for Chromium. memory.high THROTTLES, does NOT kill.
exec 2>&1 CG=/sys/fs/cgroup/chromium
for c in memory cpu io; do
    grep -qw "\$c" /sys/fs/cgroup/cgroup.subtree_control 2>/dev/null \\
        || echo "+\$c" > /sys/fs/cgroup/cgroup.subtree_control 2>/dev/null || true
done
mkdir -p "\$CG"
echo "max" > "\$CG/memory.max"      2>/dev/null
echo "8G"  > "\$CG/memory.high"     2>/dev/null
echo "4G"  > "\$CG/memory.swap.max" 2>/dev/null
echo "100" > "\$CG/cpu.weight"      2>/dev/null
chown -R ${USER_NAME}:${USER_NAME} "\$CG"
exec sleep infinity
EOF
chmod +x /etc/sv/chromium-cgroup/run
[ -L /var/service/chromium-cgroup ] || ln -s /etc/sv/chromium-cgroup /var/service/chromium-cgroup

echo "==> [6/7] Installing user-side launcher and flags"
install -d -o "$USER_NAME" -g "$USER_NAME" "$USER_HOME/bin" "$USER_HOME/.config"

cat > "$USER_HOME/bin/chromium" <<'EOF'
#!/bin/sh
# Hardened Chromium launcher: joins cgroup, lowers CPU/IO priority.
CG=/sys/fs/cgroup/chromium
[ -w "$CG/cgroup.procs" ] && echo $$ > "$CG/cgroup.procs" 2>/dev/null || true
exec ionice -c 2 -n 4 nice -n 5 /usr/bin/chromium "$@"
EOF
chmod +x "$USER_HOME/bin/chromium"
chown "$USER_NAME:$USER_NAME" "$USER_HOME/bin/chromium"

cat > "$USER_HOME/.config/chromium-flags.conf" <<'EOF'
# --- robustness: suspend tabs instead of killing them ---
--enable-features=MemorySaver,HighEfficiencyModeAvailable,DiscardRingImprovements,WebContentsDiscard
--disable-features=CalculateNativeWinOcclusion
--disk-cache-dir=/tmp/chromium-cache
--disk-cache-size=1073741824
--media-cache-size=536870912

# --- security hardening ---
--enable-features=StrictOriginIsolation,IsolateOrigins,StrictExtensionIsolation,NetworkServiceSandbox,WebUICodeCache
--isolate-origins=https://*
--site-per-process
--enable-strict-mixed-content-checking
--no-pings
--disable-features=PrivacySandboxSettings4,InterestCohort,FederatedLearningOfCohorts,Translate,OptimizationHints
--no-default-browser-check
--no-first-run

# --- Intel iGPU (ThinkPad X1) hardware video decode on musl ---
--ignore-gpu-blocklist
--enable-gpu-rasterization
--enable-zero-copy
--enable-features=VaapiVideoDecoder,VaapiVideoEncoder,AcceleratedVideoDecodeLinuxGL,CanvasOopRasterization
--use-gl=egl

# --- performance ---
--enable-features=ParallelDownloading,BackForwardCache
--enable-quic
EOF
chown "$USER_NAME:$USER_NAME" "$USER_HOME/.config/chromium-flags.conf"

# Add ~/bin to PATH in .zshrc if missing
if ! grep -q 'HOME/bin' "$USER_HOME/.zshrc" 2>/dev/null; then
    printf '\n# user bin (chromium hardened launcher)\nexport PATH="$HOME/bin:$PATH"\n' >> "$USER_HOME/.zshrc"
    chown "$USER_NAME:$USER_NAME" "$USER_HOME/.zshrc"
fi

echo "==> [7/7] Reloading sxhkd if running"
pkill -USR1 -x sxhkd 2>/dev/null || true

sleep 2
echo
echo "==> STATUS"
sv status zramen chromium-cgroup 2>/dev/null || true
echo "--- cgroup memory.high: $(cat /sys/fs/cgroup/chromium/memory.high 2>/dev/null || echo 'pending')"
echo "--- zram:"; zramctl 2>/dev/null || true
echo "--- swap:"; free -h | grep -i swap
echo
echo "DONE. Close all Chromium windows, then super+w (sxhkd) launches the hardened build."
echo "Verify: chrome://gpu  (Hardware accelerated)   chrome://discards  (suspended, not killed)"
