#!/bin/bash
# Build btreset and install it with its boot-time LaunchDaemon. Run from this folder: sudo ./install.sh
set -e
cd "$(dirname "$0")"
clang -O2 -Wall -framework IOKit -framework CoreFoundation btreset.c -o btreset
sudo mkdir -p /usr/local/libexec
sudo install -m 755 btreset btreset-check.sh /usr/local/libexec/
sudo install -m 644 com.labrouss.btreset.plist /Library/LaunchDaemons/
sudo chown root:wheel /Library/LaunchDaemons/com.labrouss.btreset.plist
sudo launchctl bootout system/com.labrouss.btreset 2>/dev/null || true
sudo launchctl bootstrap system /Library/LaunchDaemons/com.labrouss.btreset.plist
echo "Installed. Log: /var/log/btreset.log   Manual test: sudo /usr/local/libexec/btreset"
