# How to start fast with this monitoring stack

## Initial Server and software setup

Install latest ubuntu (at least 24.04) on your server or VM.

- Execute the following commands to update and upgrade your system:
```bash
sudo apt update && sudo apt upgrade -y
```

- Install latest Docker and Docker Compose v2:

```bash
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

```

- Reboot your server to ensure all changes take effect:
```bash
sudo reboot
```

- After reboot, verify Docker installation:
```bash
docker --version
docker compose version
```

## Clone this repository

```bash
git clone https://github.com/nuclearcat/collmon
cd collmon
```

## Start the monitoring stack

```bash
docker compose up -d
```
You should see all containers are first pulling latest images, then starting.

## Access the web interfaces
- Grafana: http://YOUR_SERVER_IP:3000 (default user/pass: admin/admin - you will be prompted to change it on first login)

## Configure your devices to be monitored (SNMP)
- Edit the `usnmp_exporter/usnmp_exporter.yml` file to add your devices and their SNMP community strings.
- Restart the usnmp_exporter container to apply changes after editing the config file:
```bash
docker compose restart usnmpexporter
```

Minimal configuration example for `usnmp_exporter.yml`:
```yaml
- ip: 10.1.1.1
  community: public
  version: 2c
```
This means we will monitor device at IP 10.1.1.1 with SNMP community string "public" using SNMP v2c only for interface stats.

Extended configuration example:
```yaml
- ip: 10.1.1.1
  community: public
  version: 2c
  ifmisc:
    - BaseOID: .1.3.6.1.2.1.31.1.1.1.3
      Name: ifInBroadcastPkts
    - BaseOID: .1.3.6.1.2.1.2.2.1.13
      Name: ifInDiscards
    - BaseOID: .1.3.6.1.2.1.2.2.1.14
      Name: ifInErrors
    - BaseOID: .1.3.6.1.2.1.2.2.1.19
      Name: ifOutDiscards
    - BaseOID: .1.3.6.1.2.1.2.2.1.20
      Name: ifOutErrors
    - BaseOID: .1.3.6.1.4.1.2636.3.60.1.1.1.1.8
      Name: jnxDomCurrentModuleTemperature
  oidmisc:
    - oid: .1.3.6.1.4.1.6527.3.1.2.3.54.1.43.2.4
      name: vRtrIfRxBytes
      tags:
        - key: "interface"
          value: "eth0"
        - key: "customer"
          value: "abouali"
        - key: "vprn"
          value: "moon"
    - oid: .1.3.6.1.4.1.6527.3.1.2.3.74.1.4.2.4
      name: vRtrIfTxBytes
      tags:
        - key: "interface"
          value: "eth0"
        - key: "customer"
          value: "abouali"
        - key: "vprn"
          value: "moon"
- ip: 10.1.1.2
  community: private
  version: 2c
  ifmisc:
    - BaseOID: .1.3.6.1.2.1.31.1.1.1.3
      Name: ifInBroadcastPkts

```
This means we will monitor two devices (10.1.1.1 and 10.1.1.2) with their respective SNMP community strings.
First device we will also monitor extended interface stats and some custom OIDs with tags for better identification in Grafana.
Second device we will monitor only basic interface stats and Broadcast packets on interfaces.

# 10) Grafana tips and tricks

To add new monitoring jobs, like usnmpexporter, to Grafana dashboards, follow these steps:
1. Open Grafana in your web browser and log in.
2. Navigate to the dashboard you want to modify.
3. Click on the panel title you want to edit, then select "Edit"
4. In the query editor, you can add a new query for the usnmpexporter data source, i suggest first to filter by label name "job" with value "usnmpexporter" to see all available metrics from this exporter.
5. Use the metrics browser to find the specific metrics you want to visualize.
6. Customize the visualization settings as needed.

# 11) Useful Docker commands
- View running containers:
```bash
docker ps
```
- View all containers (including stopped ones):
```bash
docker ps -a
```
- View container logs:
```bash
docker logs <container_id>
```
- Stop a running container:
```bash
docker stop <container_id>
```
- Remove a stopped container:
```bash
docker rm <container_id>
```

# 12) Useful Docker Compose commands
- View status of all services:
```bash
docker compose ps
```
- View logs of all services:
```bash
docker compose logs
```
- View logs of a specific service:
```bash
docker compose logs <service_name>
```
- Stop all services:
```bash
docker compose down
```
- Restart all services:
```bash
docker compose restart
```
- Starting up services (if not already running), also will restart if docker-compose.yml or any env file changed:
```bash
docker compose up -d
```

