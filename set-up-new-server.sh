#!/usr/bin/env bash
set -euo pipefail

# Usage: sudo ./setup-server.sh <username> "<ssh-public-key>"

if [ "$EUID" -ne 0 ]; then
  echo "Please run as root: sudo $0 <username> \"<public-key>\"" >&2
  exit 1
fi

if [ "$#" -ne 2 ]; then
  echo "Usage: sudo $0 <username> \"<ssh-public-key>\"" >&2
  exit 1
fi

NEW_USER="$1"
PUBKEY="$2"

echo "==> [1/6] Updating system packages"
apt-get update -y
DEBIAN_FRONTEND=noninteractive apt-get upgrade -y

echo "==> [2/6] Creating user: $NEW_USER"
if id "$NEW_USER" &>/dev/null; then
  echo "    User already exists, skipping creation"
else
  adduser --disabled-password --gecos "" "$NEW_USER"
fi
usermod -aG sudo "$NEW_USER"

echo "==> [3/6] Allowing sudo without a password (login is key-only)"
echo "$NEW_USER ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/90-$NEW_USER"
chmod 440 "/etc/sudoers.d/90-$NEW_USER"
visudo -cf "/etc/sudoers.d/90-$NEW_USER"

echo "==> [4/6] Installing SSH public key"
SSH_DIR="/home/$NEW_USER/.ssh"
mkdir -p "$SSH_DIR"
touch "$SSH_DIR/authorized_keys"
grep -qxF "$PUBKEY" "$SSH_DIR/authorized_keys" || echo "$PUBKEY" >> "$SSH_DIR/authorized_keys"
chmod 700 "$SSH_DIR"
chmod 600 "$SSH_DIR/authorized_keys"
chown -R "$NEW_USER:$NEW_USER" "$SSH_DIR"

echo "==> [5/6] Hardening SSH (no passwords, no root login)"
cat > /etc/ssh/sshd_config.d/01-hardening.conf <<'EOF'
PasswordAuthentication no
PermitRootLogin no
EOF
sshd -t                      # stop here if the config has an error
systemctl restart ssh

echo "==> [6/6] Configuring firewall (ufw)"
apt-get install -y ufw
ufw allow OpenSSH            # must come BEFORE enabling, or you lock yourself out
ufw allow 80/tcp
ufw allow 443/tcp
ufw --force enable
ufw status verbose

echo
echo "Setup complete. BEFORE closing this session, open a NEW terminal and test:"
echo "  ssh -i <your-private-key> $NEW_USER@<server-ip>"