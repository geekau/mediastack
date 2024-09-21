# MediaStack Project (Docker) - min-vpn_single-yaml  

Go to: [https://github.com/geekau/mediastack](https://github.com/geekau/mediastack)

Download the full "mediastack" repository to your computer by selecting "**Code**" --> "**Download Zip**"

Extract the downloaded zip file, then go to the directory which suits your deployment method

Full deployment and configuration instructions are located at: [https://MediaStack.Guide](https://MediaStack.Guide)

</br>

## What is "min-vpn_single-yaml"?

This directory contains the configuration to deploy the MediaStack in a minimal Secure VPN architecture, where only the qBittorrent client is using the VPN, and all other network traffic is sent straight out via your ISP's network connection.

This configuration uses one YAML file to deploy over 20 Docker containers. While it is only one file to deploy the entire MediaStack Project, it can be difficult to troubleshoot when there are configuration issues that need to be debugged.

Single YAML configuration is **recommended for advanced Docker users.**

</br>
<br>

## Minimal VPN Network Security

This configuration set builds a minimal encrypted VPN network, soley for the BitTorrent network traffic coming from qBittorrent, which routes network traffic through the Gluetun Docker container, where it is encrypted into a VPN before routing out to the Internet. All other Docker containers connect to the Docker bridge network (not Gluetun), and pass their network traffic directly out to the Internet though your Internet Service Provider. This approach ensures that only the BitTorrent data is encrypted, while other containers operate with unencrypted traffic flows. The advantage here is that it maintains higher network performance for most applications, avoiding the latency and bandwidth reductions associated with full encryption.  

However, this comes at the cost of leaving some network traffic potentially exposed to interception or monitoring. This setup is suitable for users who require high performance for certain applications but still want to protect specific, sensitive activities.  

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
