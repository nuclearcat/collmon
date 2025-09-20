#!/usr/bin/env bash
set -e

# Ensure script is run as root
if [[ $EUID -ne 0 ]]; then
 echo "This script must be run with sudo or as root."
 exit 1
fi

# 1) Remove any old Docker and Docker Compose packages
echo "Removing old Docker packages..."
set +e
apt-get remove -y \
 docker docker-engine docker.io docker-ce docker-ce-cli \
 containerd runc \
 docker-compose
set -e
# Note: The above command may fail if Docker is not installed, which is fine.
# The script will continue to install the latest version.

# 2) Update package index
echo "Updating APT package index..."
apt-get update -y

# 3) Install prerequisite packages
echo "Installing prerequisites..."
apt-get install -y \
 ca-certificates \
 curl \
 gnupg \
 lsb-release

# 4) Add Docker’s official GPG key
echo "Adding Docker’s GPG key..."
install -m 0755 -d /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg \
 | gpg --dearmor -o /etc/apt/keyrings/docker.gpg
chmod a+r /etc/apt/keyrings/docker.gpg

# ubuntu or debian?
KIND=$(lsb_release -is | tr '[:upper:]' '[:lower:]')
if [[ "$KIND" != "ubuntu" && "$KIND" != "debian" ]]; then
 echo "This script is intended for Ubuntu or Debian systems only."
 exit 1
fi

# 5) Set up the Docker APT repository
echo \
 "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] \
 https://download.docker.com/linux/$KIND \
 $(lsb_release -cs) stable" \
 | tee /etc/apt/sources.list.d/docker.list > /dev/null

# 6) Update the package index again
echo "Updating APT package index with Docker repo..."
apt-get update -y

# 7) Install the latest Docker Engine, CLI, containerd, and Compose plugin
echo "Installing Docker Engine, CLI, containerd, and Docker Compose plugin..."
apt-get install -y \
 docker-ce \
 docker-ce-cli \
 containerd.io \
 docker-compose-plugin

# 8) was legacy docker-compose, which we skip

# 9) Add current user to the 'docker' group (so you can run docker without sudo)
USER_NAME=${SUDO_USER:-$(whoami)}
echo "Adding user '$USER_NAME' to docker group..."
usermod -aG docker "$USER_NAME"

# 10) Enable and start Docker
echo "Enabling and starting Docker service..."
systemctl enable docker
systemctl start docker

# 11) Verify installation
echo "Verifying Docker installation..."
docker --version
docker compose version || echo "Docker Compose plugin installed; use 'docker compose'."

echo "Done! Please log out and back in (or reboot) for group changes to take effect."
