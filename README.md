This is the latest development commit of the MediaStack.Guide:  

[https://523e47ff.mediastack-guide.pages.dev/](https://523e47ff.mediastack-guide.pages.dev/).  

Unfortunately I didn't realise just how much effort was needed to write all the documentation, and the amount of additional applications and integration also grew, it became an insurmountable task.  

This dev guide is missing a lot of text / sections, but has all the steps needed to get all the apps up and running, and all configured (except for SWAG, Authelia, and Heimdal... am still working on these configs).  

If you feel you are able to contribute to the documentation, please head over the this repo: [https://github.com/geekau/mediastack-guide](https://github.com/geekau/mediastack-guide)

---

# Docker Media Stack

Go to: [https://github.com/geekau/mediastack](https://github.com/geekau/mediastack)

Download the full "mediastack" repository to your computer by selecting "**Code**" --> "**Download Zip**"

Extract the downloaded zip file, then go to the directory which suits your deployment method

Follow the deployment instructions at: [https://MediaStack.Guide](https://MediaStack.Guide)

---

## What are the different directories / deployments?

The Docker applications and services across the different directories / deployments are all extactly the same, however they differ on which Docker containers are secured via VPN for Internet traffic, and whether the MediaStack applications are deployed individually (per file), or collectively as a group (single file).

|                                                                                                                                                 | Each Docker container / application is deployed individually using multiple YAML configurations - suits new users. | Deploys all Docker containers / applications and the "mediastack" network all from the one YAML configuration - suits advanced users. |
|-------------------------------------------------------------------------------------------------------------------------------------------------|---------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|------------------------------------------------------------------------------------------------|
| All Docker containers send external Internet traffic routed through the Gluetun VPN container, to maximise overall network encryption           | full-vpn_multiple-yaml                                                                                                                                                                                                                      | full-vpn_single-yaml                                                                           |
| Only the qBittorrent container sends external Internet traffic routed through the Gluetun VPN container, to maximise overall network efficiency | min-vpn_multiple-yaml                                                                                                                                                                                                                       | min-vpn_single-yaml                                                                            |


> NOTE: If you are using deploying the YAML files one at a time (multiple deployment), you MUST deploy the Gluetun Docker container first, as it sets up the "mediastack" network for all other Docker containers to join. 
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
