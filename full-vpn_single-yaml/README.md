# MediaStack Project (Docker) - full-vpn_single-yaml  

Go to: [https://github.com/geekau/mediastack](https://github.com/geekau/mediastack)

Download the full "mediastack" repository to your computer by selecting "**Code**" --> "**Download Zip**"

Extract the downloaded zip file, then go to the directory which suits your deployment method

Full deployment and configuration instructions are located at: [https://MediaStack.Guide](https://MediaStack.Guide)

</br>

## What is "full-vpn_single-yaml"?

This directory contains the configuration to deploy the MediaStack in a minimal Secure VPN architecture, where only the qBittorrent client is using the VPN, and all other network traffic is sent straight out via your ISP's network connection.

This configuration uses one YAML file to deploy over 20 Docker containers. While it is only one file to deploy the entire MediaStack Project, it can be difficult to troubleshoot when there are configuration issues that need to be debugged.

Single YAML configuration is **recommended for advanced Docker users.**

</br>

## Full VPN Network Security  

This configuration set builds a fully encrypted VPN network architecture, and routes all network traffic from the Docker containers through the Gluetun container, where it is encrypted into a VPN, before it passes securely across the internet. This setup ensures that all data packets are encrypted, providing robust privacy and security. The primary benefit of this approach is the comprehensive protection of data, safeguarding against eavesdropping, and maintaining user privacy.  

However, this heightened security method comes with trade-offs. Encrypting and decrypting all traffic can lead to increased latency and reduced network speeds. This can particularly impact applications requiring high bandwidth or low latency, such as media streaming or real-time communication tools. Nonetheless, for users prioritising privacy and security over speed, this setup is ideal.  

</br>
<center>

``` mermaid
graph TD
    subgraph DockerNet[<center>Docker Networking - 172.28.10.0/24</center>]
        Jellyfin ---- Gluetun
        Plex --- Gluetun
        Jellyseerr ---- Gluetun
        Prowlarr --- Gluetun
        Radarr ---- Gluetun
        Readarr --- Gluetun
        Sonarr ---- Gluetun
        Mylar --- Gluetun
        Whisparr ---- Gluetun
        Bazarr --- Gluetun
        Lidarr ---- Gluetun
        Tdarr --- Gluetun
        SABnzbd ---- Gluetun
        NIC[Host Network Interface]
        qBittorrent ---- Gluetun
    end
    Gluetun ==>| Secure VPN | NIC
    NIC ==>| Secure VPN | Gateway[<center>Home</p>Gateway</center>]
    Gateway ==>|Secure VPN |VPN{<center>VPN Server</p>Anchor Point</center>}
    
    style Bazarr stroke:green,stroke-width:2px
    style Lidarr stroke:green,stroke-width:2px
    style Mylar stroke:green,stroke-width:2px
    style Prowlarr stroke:green,stroke-width:2px
    style Radarr stroke:green,stroke-width:2px
    style Readarr stroke:green,stroke-width:2px
    style Sonarr stroke:green,stroke-width:2px
    style Tdarr stroke:green,stroke-width:2px
    style Whisparr stroke:green,stroke-width:2px
    style Jellyfin stroke:green,stroke-width:2px
    style Plex stroke:green,stroke-width:2px
    style qBittorrent stroke:green,stroke-width:2px
    style Jellyseerr stroke:green,stroke-width:2px
    style SABnzbd stroke:green,stroke-width:2px
    style Gluetun stroke:green,stroke-width:2px
    style NIC stroke:green,stroke-width:2px
    style Gateway stroke:green,stroke-width:2px
    style VPN stroke:green,stroke-width:2px
```

</center>
<br><br>

> NOTE: Many of the Docker applications are passing traffic through the Gluetun VPN container. When the Gluetun container stops, or if the VPN network connection is interrupted, then all network traffic for the other Docker applications, will also stop until the secure VPN connection is re-established.

<br>

### Single YAML File Deployment:  

Advanced users often prefer a single YAML file as it encapsulates the entire network and application configurations in one place. This method simplifies management and ensures all services are deployed together, maintaining consistency and reducing the risk of configuration mismatches. However, this approach requires a deep understanding of Docker and YAML syntax, as a single error can disrupt the deployment of all services.  

Example:  

```
vi docker-compose.env
sudo docker compose --file docker-compose-mediastack.yaml --env-file docker-compose.env up -d  
```

> NOTE: You must update the **`docker-compose.env`** file for your needs, prior to running **`docker compose`**.  

</br>
---

Follow the deployment instructions at: [https://MediaStack.Guide](https://MediaStack.Guide)

See you on [Reddit for MediaStack](https://www.reddit.com/r/MediaStack/)

---
