#!/bin/bash
# Plasma lock as root uses PAM and almost always rejects the real password.
mkdir -p /root/.config /etc/xdg
cat > /etc/xdg/kscreenlockerrc <<'EOF'
[Daemon]
Autolock=false
LockOnResume=false
LockOnLid=false
Timeout=0
EOF
cp -f /etc/xdg/kscreenlockerrc /root/.config/kscreenlockerrc

faillock --user root --reset >/dev/null 2>&1 || true
killall -9 kscreenlocker_greet kscreenlocker >/dev/null 2>&1 || true
loginctl unlock-sessions >/dev/null 2>&1 || true

# Make the greeter non-executable so Meta+L cannot lock you out again.
find /usr -name 'kscreenlocker_greet' -exec chmod a-x {} + 2>/dev/null || true
