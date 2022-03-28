Monitoring solution
============
Based on VictoriaMetrics + collectd + Prometheus blackbox exporter + grafana

## Quickstart

- sudo docker-compose up --build -d
- Open in browser http://127.0.0.1:3000/ and user admin/admin username and password.
- To add more remote hosts services to monitor (DNS, HTTP, etc) check blackbox-exporter/blackbox.yml
- To add collectd on remote host check external-example/ directory.
On remote host install collectd with --no-install-recommends, otherwise in ubuntu it might install full graphical desktop.
E.g.: apt install --no-install-recommends collectd

## How to clean up and start fresh
### Print out the list of files and directories which will be removed (dry run)
sudo git clean -n -d
### Delete the files from the repository
sudo git clean -fd
### Delete volumes, networks and etc
sudo docker-compose down

## Final notes:
Largely based on https://github.com/VictoriaMetrics/VictoriaMetrics


