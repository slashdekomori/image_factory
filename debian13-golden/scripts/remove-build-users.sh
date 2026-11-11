#!/usr/bin/env bash
# Runs detached as root at the very end of the build.
set -u

BUILD_USERS="packer debian"

# Give Packer time to finish and close its SSH session
sleep 5

# Kill anything still running as those users
for u in $BUILD_USERS; do
    pkill -KILL -u "$u" 2>/dev/null || true
done
sleep 1

# Remove the users and their home directories
for u in $BUILD_USERS; do
    if id "$u" >/dev/null 2>&1; then
        userdel -r -f "$u"
    fi
done

# Remove the sudo rules and the cloud-init SSH drop-in
rm -f /etc/sudoers.d/90-cloud-init-users
rm -f /etc/ssh/sshd_config.d/*cloud-init*.conf

# Trim after the deletions so the freed blocks are included
fstrim -av || true

# Delete this script, then power off
rm -f -- "$0"
shutdown -P now
