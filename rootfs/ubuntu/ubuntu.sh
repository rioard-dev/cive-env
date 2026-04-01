#!/bin/bash
# Setup Ubuntu 20.04.2 armhf dengan proot - menghindari hard link error

set -e

ROOTFS_DIR="ubuntu-rootfs"
TARBALL="ubuntu-base-20.04.2-base-armhf.tar.gz"
URL="https://github.com/rioard-dev/cive-env/raw/refs/heads/main/rootfs/ubuntu/ubuntu-base-twenty.tar.gz"


echo "=== Setup Ubuntu Focal armhf Rootfs (Fix Hard Link Error) ==="

# Download
if [ ! -f "$TARBALL" ]; then
    echo "Downloading..."
    wget -q --show-progress "$URL" -O "$TARBALL"
fi

# Buat folder
rm -rf "$ROOTFS_DIR"  # hapus jika sudah ada (untuk clean install)
mkdir -p "$ROOTFS_DIR"

echo "Extracting rootfs dengan --link2symlink (ini menghindari error hard link)..."
proot --link2symlink -0 tar -xzf "$TARBALL" -C "$ROOTFS_DIR" --warning=no-timestamp || true

echo "Setup konfigurasi dasar..."

# DNS
echo "nameserver 8.8.8.8" > "$ROOTFS_DIR/etc/resolv.conf"
echo "nameserver 1.1.1.1" >> "$ROOTFS_DIR/etc/resolv.conf"

# Sources.list (ports.ubuntu.com)
cat > "$ROOTFS_DIR/etc/apt/sources.list" << EOF
deb http://ports.ubuntu.com/ubuntu-ports focal main restricted universe multiverse
deb http://ports.ubuntu.com/ubuntu-ports focal-updates main restricted universe multiverse
deb http://ports.ubuntu.com/ubuntu-ports focal-security main restricted universe multiverse
deb http://ports.ubuntu.com/ubuntu-ports focal-backports main restricted universe multiverse
EOF


# Script login (start-ubuntu.sh)
cat > start-ubuntu.sh << 'EOF'
ROOTFS_DIR="ubuntu-rootfs"

echo "Fixing common broken parts..."
mkdir -p "$ROOTFS_DIR/tmp" "$ROOTFS_DIR/dev" "$ROOTFS_DIR/proc" "$ROOTFS_DIR/sys" "$ROOTFS_DIR/run"

chmod 1777 "$ROOTFS_DIR/tmp"
unset LD_PRELOAD   # Important! Termux's LD_PRELOAD can conflict with proot

proot --link2symlink -0 -r "$ROOTFS_DIR" \
    -b /dev \
    -b /proc \
    -b /sys \
    -b /tmp \
    -b /sdcard:/sdcard \
    -b /storage:/storage \
    -w /root \
    /usr/bin/env -i \
    HOME=/root \
    PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin \
    TERM=xterm-256color \
    /bin/bash --login
EOF

chmod +x start-ubuntu.sh

echo ""
echo "✅ Setup selesai!"
echo "Jalankan dengan perintah:"
echo "   ./start-ubuntu.sh"

rm -r "$TARBALL"
bash start-ubuntu.sh