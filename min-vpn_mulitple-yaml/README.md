# Docker Media Stack: min-vpn_multiple-yaml

Go to: [https://github.com/geekau/media-stack](https://github.com/geekau/media-stack)

Download the full "media-stack" repository to your computer by selecting "**Code**" --> "**Download Zip**"

Extract the downloaded zip file, then go to the directory which suits your deployment method

Follow the deployment instructions at: [https://MediaStack.Guide](https://MediaStack.Guide)

---

## What is "min-vpn_multiple-yaml"?

Only the qBittorrent container sends external Internet traffic routed through the Gluetun VPN container, all other Docker containers send their Internet traffic directly out your home Internet connection. If there is no active VPN connection, then only the qBittorrent container stops sending Internet traffic. This is the fastest and most efficient network connection setup, as only Torrent traffic uses the VPN, however it is not the most secure overall.

This build is broken down into "individual" Docker Compose build configuration files (YAML), so each Docker application / container is deployed one at a time, rather than an all-applications-at-once deployment.

The individual deployment method is ideal for beginners and also allows for easy testing and fault finding when deployment issues occur.

> NOTE: All incoming Internet traffic still goes through Cloudflare DNS and Zero Trust Network Access services, so the network configuration for SWAG (reverse proxy), Authelia, Heimdall and DDNS-Updater applications are not configured to use the Gluetun VPN, as Cloudflare will proxy your inbound Internet traffic directly to your IP Address / Internet connection. SWAG is build to secure all inbound network traffic from the Internet, refer to [https://MediaStack.Guide](https://MediaStack.Guide) for instructions on setting up Internet access to your internal Docker environment.

---

## TL;DR

1. Update settings in `docker-compose.env` to suit your VPN account, local networking, and location of Docker Configuration Files / Media Storage

2. Deploy the Gluetun VPN container first (`docker-compose-gluetun.yaml`), then deploy the remaining Docker containers

3. Import `MediaStack.Guide Applications` bookmarks into your web browser, to easily access each application
