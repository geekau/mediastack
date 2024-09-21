# MediaStack Project (Docker) - min-vpn_single-yaml  

Go to: [https://github.com/geekau/mediastack](https://github.com/geekau/mediastack)

Download the full "mediastack" repository to your computer by selecting "**Code**" --> "**Download Zip**"

Extract the downloaded zip file, then go to the directory which suits your deployment method

Full deployment and configuration instructions are located at: [https://MediaStack.Guide](https://MediaStack.Guide)

</br>

## What is "min-vpn_single-yaml"?

This directory contains the configuration to deploy the MediaStack in a minimal Secure VPN architecture, where only the qBittorrent client is using the VPN, and all other network traffic is sent straight out via your ISP's network connection.

This configuration uses multiple YAML files to deploy over 20 Docker containers. It may take a little longer to deploy and get your MediaStack Project containers deployed, it is much easier to troubleshoot problems when there are configuration issues that need to be debugged.

Multiple YAML configuration files is **recommended for new Docker users, and for fault finding activities.**

</br>
<center>

``` mermaid
graph TD
    subgraph DockerNet[<center>Docker Networking - 172.28.10.0/24</center>]
        Jellyfin -..-> NIC
        Plex -.-> NIC
        Jellyseerr -..-> NIC
        Prowlarr -.-> NIC
        Radarr -..-> NIC
        Readarr -.-> NIC
        Sonarr -..-> NIC
        Mylar -.-> NIC
        Whisparr -..-> NIC
        Bazarr -.-> NIC
        Lidarr -..-> NIC
        Tdarr -.-> NIC
        SABnzbd -..-> NIC
        NIC[Host Network Interface]
        qBittorrent --- Gluetun
    end
    Gluetun ==>| Secure VPN | NIC
    NIC -.->| Insecure Data | Gateway[<center>Home</p>Gateway</center>]
    NIC ==>| Secure VPN | Gateway[<center>Home</p>Gateway</center>]
    Gateway -.->| Insecure Data |Internet{<center>General</p>Internet</center>}
    Gateway ==>|Secure VPN |VPN{<center>VPN Server</p>Anchor Point</center>}
    
    style Bazarr stroke:orange,stroke-width:2px
    style Lidarr stroke:orange,stroke-width:2px
    style Mylar stroke:orange,stroke-width:2px
    style Prowlarr stroke:orange,stroke-width:2px
    style Radarr stroke:orange,stroke-width:2px
    style Readarr stroke:orange,stroke-width:2px
    style Sonarr stroke:orange,stroke-width:2px
    style Tdarr stroke:orange,stroke-width:2px
    style Whisparr stroke:orange,stroke-width:2px
    style Jellyfin stroke:orange,stroke-width:2px
    style Plex stroke:orange,stroke-width:2px
    style qBittorrent stroke:green,stroke-width:2px
    style Jellyseerr stroke:orange,stroke-width:2px
    style SABnzbd stroke:orange,stroke-width:2px
    style Gluetun stroke:green,stroke-width:2px
    style VPN stroke:green,stroke-width:2px
    style Internet stroke:orange,stroke-width:2px
```

</center>
<br><br>

> NOTE: Many of the Docker applications are passing traffic through the Gluetun VPN container. When the Gluetun container stops, or if the VPN network connection is interrupted, then all network traffic for the other Docker applications, will also stop until the secure VPN connection is re-established.

<br>

### Multiple YAML Files Deployment:  

New users benefit from using multiple YAML files, each dedicated to an individual Docker application. This modular approach simplifies troubleshooting and allows users to manage each service independently. If an issue arises, it’s easier to pinpoint and resolve. Additionally, it provides flexibility to update or redeploy specific applications without affecting the entire stack.  

**If you choose to deploy the Docker containers individually, you MUST deploy the Gluetun container first**. The Gluetun Docker container sets up the essential network configurations that establish the foundational network infrastructure for all other Docker containers. Without it, subsequent deployments will fail, as they rely on the network settings defined within the Gluetun YAML file. This prerequisite ensures that all containers can communicate correctly and securely within the Docker network.

> NOTE: You must update the **`docker-compose.env`** file for your needs, prior to running **`docker compose`**.  

Example:  

```
vi docker-compose.env
sudo docker compose --file docker-compose-gluetun.yaml      --env-file docker-compose.env up -d  

sudo docker compose --file docker-compose-jellyfin.yaml     --env-file docker-compose.env up -d  
sudo docker compose --file docker-compose-jellyseerr.yaml   --env-file docker-compose.env up -d  
sudo docker compose --file docker-compose-plex.yaml         --env-file docker-compose.env up -d  

sudo docker compose --file docker-compose-prowlarr.yaml     --env-file docker-compose.env up -d  
sudo docker compose --file docker-compose-lidarr.yaml       --env-file docker-compose.env up -d  
sudo docker compose --file docker-compose-mylar.yaml        --env-file docker-compose.env up -d  
sudo docker compose --file docker-compose-radarr.yaml       --env-file docker-compose.env up -d  
sudo docker compose --file docker-compose-readarr.yaml      --env-file docker-compose.env up -d  
sudo docker compose --file docker-compose-sonarr.yaml       --env-file docker-compose.env up -d  
sudo docker compose --file docker-compose-whisparr.yaml     --env-file docker-compose.env up -d  
sudo docker compose --file docker-compose-bazarr.yaml       --env-file docker-compose.env up -d  

sudo docker compose --file docker-compose-qbittorrent.yaml  --env-file docker-compose.env up -d  
sudo docker compose --file docker-compose-sabnzbd.yaml      --env-file docker-compose.env up -d  

sudo docker compose --file docker-compose-unpackerr.yaml    --env-file docker-compose.env up -d  
sudo docker compose --file docker-compose-tdarr.yaml        --env-file docker-compose.env up -d  

sudo docker compose --file docker-compose-swag.yaml         --env-file docker-compose.env up -d  
sudo docker compose --file docker-compose-authelia.yaml     --env-file docker-compose.env up -d  
sudo docker compose --file docker-compose-heimdall.yaml     --env-file docker-compose.env up -d  
sudo docker compose --file docker-compose-ddns-updater.yaml --env-file docker-compose.env up -d  
sudo docker compose --file docker-compose-flaresolverr.yaml --env-file docker-compose.env up -d  

sudo docker compose --file docker-compose-portainer.yaml    --env-file docker-compose.env up -d  
```

Additionally, if there are some Docker applications you do not want to run in your MediaStack, then you just don't run the **`docker compose`** command for these applications.

</br>
---

Follow the deployment instructions at: [https://MediaStack.Guide](https://MediaStack.Guide)

See you on [Reddit for MediaStack](https://www.reddit.com/r/MediaStack/)

---
