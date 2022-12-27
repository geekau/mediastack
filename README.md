# Docker Media Stack

Go to: [https://github.com/geekau/media-stack](https://github.com/geekau/media-stack)

Download the full "media-stack" repository to your computer by selecting "**Code**" --> "**Download Zip**"

Extract the downloaded zip file, then go to the directory which suits your deployment method

Follow the deployment instructions at: [https://MediaStack.Guide](https://MediaStack.Guide)

---

## What are the different directories / deployments?

The Docker applications and services across the different directories / deployments are all extactly the same, however they differ on which Docker containers are secured via VPN for Internet traffic, and whether the MediaStack applications are deployed individually (per file), or collectively as a group (single file).

---

## Directory: full-vpn_multiple-yaml

 - All Docker containers send external Internet traffic routed through the Gluetun VPN container, to maximise overall network encryption
 - Each Docker container is deployed separately, using its own individual docker-compose deployment file
 - Gluetun VPN container must be deployed first, as it sets up the network stack and the VPN connection for all other containers to use

---

## Directory: full-vpn_single-yaml

 - All Docker containers send external Internet traffic routed through the Gluetun VPN container, to maximise overall network encryption
 - All Docker containers are deployed collectively, with all applications sharing a single docker-compose deployment file
 - The network stack and VPN connection are set up as the complete Docker environment is deployed

---

## Directory: min-vpn_multiple-yaml

 - Only the qBittorrent container sends external Internet traffic routed through the Gluetun VPN container, to maximise overall network efficiency
 - Each Docker container is deployed separately, using its own individual docker-compose deployment file
 - Gluetun VPN container must be deployed first, as it sets up the network stack and the VPN connection for all other containers to use

---

## Directory: min-vpn_single-yaml

 - Only the qBittorrent container sends external Internet traffic routed through the Gluetun VPN container, to maximise overall network efficiency
 - All Docker containers are deployed collectively, with all applications sharing a single docker-compose deployment file
 - The network stack and VPN connection are set up as the complete Docker environment is deployed

> NOTE: You can swap between the different deployments as / whenever you need, however you will need to ensure any configuration settings made in the `docker-compose.env` file, are copied into the new deployment folder.

---

## What about Inbound Internet traffic?

Regardless of which deployment you chose above, all incoming Internet traffic still goes through Cloudflare DNS and Zero Trust Network Access services, so the network configuration for SWAG (reverse proxy / application gateway), Authelia, Heimdall and DDNS-Updater applications are not configured to use the Gluetun VPN, as Cloudflare will proxy your inbound Internet traffic directly to your IP Address / Internet connection. SWAG is build to secure all inbound network traffic from the Internet, refer to [https://MediaStack.Guide](https://MediaStack.Guide) for instructions on setting up Internet access to your internal Docker environment.

---

## VPN / Network Connectivity Matrix

The following table shows which applications do, and do not, use the secure VPN connection, depending on the deployment method you initially choose.

Container    | Full VPN   | Min VPN
-------------|:----------:|:---------:
Authelia     | No - Never | No - Never
Bazarr       | Yes        | No
DDNS-Updater | No - Never | No - Never
Flaresolverr | Yes        | No
Gluetun      | N/A        | N/A
Heimdall     | No - Never | No - Never
Jellyfin     | Yes        | No
Jellyseerr   | Yes        | No
Lidarr       | Yes        | No
Mylar3       | Yes        | No
Prowlarr     | Yes        | No
qBittorrent  | Yes - Must | Yes - Must 
Radarr       | Yes        | No
Readarr      | Yes        | No
SABnzbd      | Yes        | No
Sonarr       | Yes        | No
SWAG         | No - Never | No - Never
Tdarr        | Yes        | No
Tdarr-Node   | Yes        | No
Unpackerr    | No Network | No Network
Whisparr     | Yes        | No
Portainer    | Bridge     | Bridge

> Must = Container MUST always connect via VPN container \
> Never = Container should NEVER connect via VPN container

---

## TL;DR

1.  Download the full "media-stack" repository to your computer

2.  Extract the downloaded zip file, then go to the directory which suits your deployment method

3. Update settings in `docker-compose.env` to suit your VPN account, local networking, and location of Docker Configuration Files / Media Storage

4. Deploy all Docker containers - If deploying containers individually, the Gluetun VPN container must be deployed first

5. Import "MediaStack.Guide Applications" bookmarks into your web browser to easily access each WebUI portal

---

See you at: [https://MediaStack.Guide](https://MediaStack.Guide)
