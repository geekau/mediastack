
⠀
# Docker Media Stack
>You can download these files easily, by going to https://github.com/geekau/media-stack then selecting "**Code**" --> "**Download Zip**".

These Docker Compose configurations will help you rapidly deploy all the applications you need in a Docker stack, to operate a Jellyfin, Jellyseerr, Torrent, Usenet, \*ARR Media Library Managers, Reverse Proxy, MFA Authenticated Access, and Tdarr Automated Media Transcoding enabled media stack, and has been thoroughly testing on Linux, Windows and Synology NAS servers.

## 1 - Prepare / rename media library if needed:
If you are setting up your media server and media libraries for the very first time, or your media is very poorly named, it is recommended you use Filebot with the following naming standards below, to initially sort all of your media. Otherwise the Media Library Managers and Jellyfin may not be able to identify your media titles, media art, and subtitles, if the original filenames are of a poor standard.

Change "**D:/Storage**" to suit your needs, however use the same disk as the original media, so it is renamed quickly in place, rather than copied to a different disk or network; this could take a great deal of time to complete depending on size of the libraries / media you are renaming.
>This can be skipped if you have a well organised / structured media library already.

**Filebot Renaming Preset String for Series / TV Shows:**
```
D:/Storage/renamed/series/{ny.colon(' - ').ascii()} [tmdbid-{id}]/Season {s00}/{ny.colon(' - ').ascii()} {s00e00} - {t.ascii()} {" - $hd $vf $vc $ac"}
```

**Filebot Renaming Preset String for Movies / Adult:**
```
D:/Storage/renamed/movies/{ny.colon(' - ').ascii()} [imdbid-{imdbid}]/{ny.colon(' - ').ascii()} {" - $hd $vf $vc $ac"}
```

**Filebot Renaming Preset String for Music / Audio:**
```
D:/Storage/renamed/music/{artist.upperInitial().ascii()}/{album.upperInitial().ascii()} ({y})/{albumArtist.upperInitial().ascii()} - {album.upperInitial().ascii()} - {pi.pad(3)+' - '} {t.ascii()}
```

## 2 - Edit the "docker-compose.env" file, and update variables to suit your environment.


```
DOCKER_SUBNET=172.28.10.0/24
DOCKER_GATEWAY=172.28.10.1
LOCAL_SUBNET=10.168.1.0/24
LOCAL_DOCKER_IP=10.168.1.111
```


### Docker Host Folders Locations:
Add the folder locations to the ENV file, where your docker configurations and media / downloads will be stored:
>Folders need to exist before running "docker-compose" commands. Valid choices are Linux, Windows or NAS folder naming conventions.
```
FOLDER_FOR_CONFIGS=/home/geekau/docker
FOLDER_FOR_MEDIA=/home/geekau/media-stack
```

### At Linux / Synology terminal, use the "id" command to identify user ID and group ID.
```
sudo id geekau
uid=1000(geekau) gid=1000(geekau) groups=1000(geekau)
```
Update the ENV file with these details:
```
PUID=1000     <-- Update this value from "id" command
PGID=1000     <-- Update this value from "id" command
TIMEZONE=Australia/Brisbane
```
Update your local Timezone using this list: [List of tz database time zones - Wikipedia](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones)

### Update your VPN Service Provider details for Gluetun to create VPN tunnel.
Add your VPN service provider details.
>If you don't have a VPN service provider configured, Gluetun will not establish a secure VPN tunnel, and will not allow any network traffic out onto the Internet.
```
VPN_SERVICE_PROVIDER=VPN provider name
VPN_USERNAME=<username from VPN provider>
VPN_PASSWORD=<password from VPN provider>
SERVER_REGION=<regions supported by VPN provider>
```
== **All containers are initally configured to sit behind the VPN connection for security / privacy. If you want the containers to have direct Internet access, follow the steps in each of the YAML files to change the network configuration, and restart the container.** ==

## 3 - Set up all of the folders / subfolders:
The commands suit the folders defined above in your ENV file for **FOLDER_FOR_CONFIGS** and **FOLDER_FOR_MEDIA**.

### For Linux hosted data folders:
If you used Linux / NAS folders in the ENV file, then use the following commands to create the necessary folders:
```
export FOLDER_FOR_CONFIGS=/home/geekau/docker
export FOLDER_FOR_MEDIA=/home/geekau/media-stack

sudo -E mkdir -p $FOLDER_FOR_CONFIGS/{authelia,bazarr,ddns-updater,gluetun,heimdall,jellyfin,jellyseerr,lidarr,mylar3,portainer,prowlarr,qbittorrent,radarr,readarr,sabnzbd,sonarr,swag,tdarr,tdarr_transcode_cache,unpackerr,whisparr}
sudo -E mkdir -p $FOLDER_FOR_MEDIA/media/{adult,anime,audio,books,comics,movies,music,photos,podcasts,series,software}
sudo -E mkdir -p $FOLDER_FOR_MEDIA/usenet/{adult,anime,audio,books,comics,movies,music,prowlarr,podcasts,series,software}
sudo -E mkdir -p $FOLDER_FOR_MEDIA/torrents/{adult,anime,audio,books,comics,movies,music,prowlarr,podcasts,series,software}
sudo -E mkdir -p $FOLDER_FOR_MEDIA/watch
sudo -E chmod -R 775 $FOLDER_FOR_CONFIGS $FOLDER_FOR_MEDIA
sudo -E chown -R geekau:geekau $FOLDER_FOR_CONFIGS $FOLDER_FOR_MEDIA
```
### For Window hosted data folders:
If you used Windows folders in the ENV file, then use the following commands to create the necessary folders:
```
set FOLDER_FOR_CONFIGS=D:\Storage\Docker
set FOLDER_FOR_MEDIA=D:\Storage\Media-Stack

FOR /D %I IN (authelia bazarr ddns-updater gluetun heimdall jellyfin jellyseerr lidarr mylar3 portainer prowlarr qbittorrent radarr readarr sabnzbd sonarr swag tdarr tdarr_transcode_cache unpackerr whisparr) DO mkdir %FOLDER_FOR_CONFIGS%\%I
FOR /D %I IN (adult anime audio books comics movies music photos podcasts series software) DO mkdir %FOLDER_FOR_MEDIA%\media\%I
FOR /D %I IN (adult anime audio books comics movies music podcasts prowlarr series software) DO mkdir %FOLDER_FOR_MEDIA%\usenet\%I
FOR /D %I IN (adult anime audio books comics movies music podcasts prowlarr series software) DO mkdir %FOLDER_FOR_MEDIA%\torrents\%I
mkdir %FOLDER_FOR_MEDIA%\watch
```
### Folder mappings between host and Docker containers:
After you run the commands above (Linux or Windows), **this will be your folder structure INSIDE your docker containers**:
```
tree /home/geekau/media-stack

⠀⠀⠀⠀⠀Host Computer:⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀Inside Containers:
├── /FOLDER_FOR_MEDIA   ⠀   ├── /data
⠀⠀⠀⠀⠀├── media      ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀├── media        <-- Media is located / managed under this folder
⠀⠀⠀⠀⠀│⠀⠀⠀⠀├── adult⠀⠀⠀⠀⠀⠀⠀⠀ ⠀⠀⠀⠀⠀⠀⠀│⠀⠀⠀⠀├── adult
⠀⠀⠀⠀⠀│⠀⠀⠀⠀├── anime⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀│⠀⠀⠀⠀├── anime
⠀⠀⠀⠀⠀│⠀⠀⠀⠀├── audio⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀│⠀⠀⠀⠀├── audio
⠀⠀⠀⠀⠀│⠀⠀⠀⠀├── books⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀│⠀⠀⠀⠀├── books
⠀⠀⠀⠀⠀│⠀⠀⠀⠀├── comics⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀│⠀⠀⠀⠀├── comics
⠀⠀⠀⠀⠀│⠀⠀⠀⠀├── movies⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀│⠀⠀⠀⠀├── movies
⠀⠀⠀⠀⠀│⠀⠀⠀⠀├── music⠀⠀⠀⠀⠀⠀⠀⠀ ⠀⠀⠀⠀⠀⠀⠀│⠀⠀⠀⠀├── music
⠀⠀⠀⠀⠀│⠀⠀⠀⠀├── photos⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀│⠀⠀⠀⠀├── photos
⠀⠀⠀⠀⠀│⠀⠀⠀⠀├── podcasts⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀│⠀⠀⠀⠀├── podcasts
⠀⠀⠀⠀⠀│⠀⠀⠀⠀├── series⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀│⠀⠀⠀⠀├── series
⠀⠀⠀⠀⠀│⠀⠀⠀⠀└── software⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀│⠀⠀⠀⠀└── software
⠀⠀⠀⠀⠀├── torrents⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀├── torrents     <-- Downloads for Torrent data
⠀⠀⠀⠀⠀│⠀⠀⠀⠀├── adult⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀│⠀⠀⠀⠀├── adult
⠀⠀⠀⠀⠀│⠀⠀⠀⠀├── anime⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀│⠀⠀⠀⠀├── anime
⠀⠀⠀⠀⠀│⠀⠀⠀⠀├── audio⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀│⠀⠀⠀⠀├── audio
⠀⠀⠀⠀⠀│⠀⠀⠀⠀├── books⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀│⠀⠀⠀⠀├── books
⠀⠀⠀⠀⠀│⠀⠀⠀⠀├── comics⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀│⠀⠀⠀⠀├── comics
⠀⠀⠀⠀⠀│⠀⠀⠀⠀├── movies⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀│⠀⠀⠀⠀├── movies
⠀⠀⠀⠀⠀│⠀⠀⠀⠀├── music⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀│⠀⠀⠀⠀├── music
⠀⠀⠀⠀⠀│⠀⠀⠀⠀├── podcasts⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀│⠀⠀⠀⠀├── podcasts
⠀⠀⠀⠀⠀│⠀⠀⠀⠀├── prowlarr⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀│⠀⠀⠀⠀├── prowlarr
⠀⠀⠀⠀⠀│⠀⠀⠀⠀├── series⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀│⠀⠀⠀⠀├── series
⠀⠀⠀⠀⠀│⠀⠀⠀⠀└── software⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀ │⠀⠀⠀⠀└── software
⠀⠀⠀⠀⠀├── usenet⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀├── usenet       <-- Downloads for Usenet data
⠀⠀⠀⠀⠀│⠀⠀⠀⠀├── adult⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀│⠀⠀⠀⠀├── adult
⠀⠀⠀⠀⠀│⠀⠀⠀⠀├── anime⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀│⠀⠀⠀⠀├── anime
⠀⠀⠀⠀⠀│⠀⠀⠀⠀├── audio⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀│⠀⠀⠀⠀├── audio
⠀⠀⠀⠀⠀│⠀⠀⠀⠀├── books⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀│⠀⠀⠀⠀├── books
⠀⠀⠀⠀⠀│⠀⠀⠀⠀├── comics⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀│⠀⠀⠀⠀├── comics
⠀⠀⠀⠀⠀│⠀⠀⠀⠀├── movies⠀⠀⠀⠀⠀⠀⠀⠀⠀ ⠀⠀⠀⠀⠀│⠀⠀⠀⠀├── movies
⠀⠀⠀⠀⠀│⠀⠀⠀⠀├── music⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀ ⠀⠀⠀⠀⠀│⠀⠀⠀⠀├── music
⠀⠀⠀⠀⠀│⠀⠀⠀⠀├── podcasts⠀⠀⠀⠀⠀⠀⠀ ⠀⠀⠀⠀⠀│⠀⠀⠀⠀├── podcasts
⠀⠀⠀⠀⠀│⠀⠀⠀⠀├── prowlarr⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀│⠀⠀⠀⠀├── prowlarr
⠀⠀⠀⠀⠀│⠀⠀⠀⠀├── series⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀ ⠀│⠀⠀⠀⠀├── series
⠀⠀⠀⠀⠀│⠀⠀⠀⠀└── software⠀⠀⠀⠀⠀⠀ ⠀⠀⠀⠀⠀ │⠀⠀⠀⠀└── software
⠀⠀⠀⠀⠀└── watch      ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀└── watch       <-- Add .nzb and .torrent files for manual download

```

## 4 - Install the Docker applications individually as you need them.

**NOTE: Gluetun MUST be installed as the first container**, as it sets up the VPN and the internal Bridge network the other containers will join (**media_network**).


### Deploy VPN and Internal Docker Bridge "media_network":
```
sudo docker-compose --file docker-compose-gluetun.yaml --env-file docker-compose.env up -d
```
**NOTE - Windows users:** Do not use the "**sudo**" at the front of the commands.

==**NOTE:**  "WARNING: Found orphan containers (gluetun, qbittorrent, sabnzbd, prowlarr, prowlarr) for this project"==

This ==WARNING== can be safely ignored, as we're loading the project apps one at a time, rather than all in one YAML file.

## Deploy Media Server and Content Request Manager:
```
sudo docker-compose --file docker-compose-jellyfin.yaml     --env-file docker-compose.env up -d
sudo docker-compose --file docker-compose-jellyseerr.yaml   --env-file docker-compose.env up -d
```


## Deploy Index Manager and Media Library Managers:
```
sudo docker-compose --file docker-compose-prowlarr.yaml --env-file docker-compose.env up -d
sudo docker-compose --file docker-compose-lidarr.yaml   --env-file docker-compose.env up -d
sudo docker-compose --file docker-compose-mylar3.yaml   --env-file docker-compose.env up -d
sudo docker-compose --file docker-compose-radarr.yaml   --env-file docker-compose.env up -d
sudo docker-compose --file docker-compose-readarr.yaml  --env-file docker-compose.env up -d
sudo docker-compose --file docker-compose-sonarr.yaml   --env-file docker-compose.env up -d
sudo docker-compose --file docker-compose-whisparr.yaml --env-file docker-compose.env up -d
sudo docker-compose --file docker-compose-bazarr.yaml   --env-file docker-compose.env up -d
```


## Deploy Download Clients:
```
sudo docker-compose --file docker-compose-qbittorrent.yaml --env-file docker-compose.env up -d
sudo docker-compose --file docker-compose-sabnzbd.yaml     --env-file docker-compose.env up -d
```


## Deploy Archive Unpacker and Automatic Video Re-encoding:
```
sudo docker-compose --file docker-compose-unpackerr.yaml --env-file docker-compose.env up -d
sudo docker-compose --file docker-compose-tdarr.yaml     --env-file docker-compose.env up -d
```


## Deploy Reverse Proxy (with SSL Certbot) and Cloudflare Proxy
```
sudo docker-compose --file docker-compose-swag.yaml         --env-file docker-compose.env up -d
sudo docker-compose --file docker-compose-authelia.yaml     --env-file docker-compose.env up -d
sudo docker-compose --file docker-compose-heimdall.yaml     --env-file docker-compose.env up -d
sudo docker-compose --file docker-compose-ddns-updater.yaml --env-file docker-compose.env up -d
sudo docker-compose --file docker-compose-flaresolverr.yaml --env-file docker-compose.env up -d
```
>The "your-domain-name.com" / IP Address validation is performed when the container is started for the first time. Nginx won't be up and start the web server, until ssl certs are successfully generated and installed.

## Deploy Portainer-CE to View Docker via GUI
```
sudo docker-compose --file docker-compose-portainer.yaml    --env-file docker-compose.env up -d
```



## Application Portals:

 Portal | Application | Function
-------- | -------- | --------
https://docker-host:9443|Portainer|GUI Interface for Docker Management
http://docker-host:6767|Bazarr|Subtitle Manager for Radarr / Sonarr
http://docker-host:8191|FlareSolverr|Provides status message only
http://docker-host:8096|Jellyfin|(Media Player)
http://docker-host:5055|Jellyseerr|(Content Request Management)
http://docker-host:8686|Lidarr|(Library Manager - Music)
http://docker-host:8090|Mylar3|(Library Manager - Comics)
http://docker-host:9696|Prowlarr|(Index and Search Management)
http://docker-host:7878|Radarr|(Library Manager - Movies)
http://docker-host:8787|Readarr|(Library Manager - Books)
http://docker-host:8100|SABnzbd|(Library Manager - TV Shows)
http://docker-host:8989|Sonarr|(Library Manager - TV Shows)
http://docker-host:8265|Tdarr|Automatic Audio/Video Library Transcoding
http://docker-host:6969|Whisparr|(Library Manager - XXX)
http://docker-host:8200|qBittorrent|(Downloader - Torrents)
http://docker-host:5080|SWAG - Nginx|Web Server for Reverse Proxy HTTP
http://docker-host:5433|SWAG - Nginx|Web Server for Reverse Proxy HTTPS
http://docker-host:6500|DDNS-Updater|Web Portal - DDNS-Updater Status

**Default qBittorrent Portal Access:**     Username: **admin**     Password: **adminadmin**

**NOTE: If the qBittorrent portal fails to load with an error message**, it may be due to the themepark module, this can be resolved by editing "FOLDER_FOR_CONFIGS/qbittorrent/qBittorrent/qBittorrent.conf" and changing "WebUI\AlternativeUIEnabled=true" to "false" and restarting qBittorrent.

## For Reverse Proxy into your network (from the Internet):

 Portal | Application | Function
-------- | -------- | --------
http://your-domain-name.com|SWAG|Reverse Proxy
https://your-domain-name.com|SWAG|Reverse Proxy

The SWAG container provides Nginx Reverse Proxy and MFA running on ports **5080/HTTP** and **5443/HTTPS**, so they don't conflict with other services running on the Docker host computer. To access your Reverse Proxy from the Internet, you need to set up your gateway / router, to allow Internet ports **80** and **443** into your network, but redirect them to the Docker host IP Address on ports **5080** and **5443** respectively.

Port **80** will be accessible on the Internet and redirected to the Reverse Proxy on port **5080**, however it will redirect to HTTPS protocol using port **443** via the Internet, which will also be redirected to the Reverse Proxy on port **5443**. Reverse Proxy port numbers can be changed as required in the ENV file if required.

The SWAG container requires a resolvable domain name, and will automatically install SSL certificates using either Let's Encrypt or Zero SSL providers, and is also able to provide Multi-Factor Authentication (MFA), to provide strong security for your Internet connected applications.

 - https://www.linuxserver.io/blog/zero-trust-hosting-and-reverse-proxy-via-cloudflare-swag-and-authelia



## Configuring DDNS-Updater for Reverse Proxy

Reference: https://hub.docker.com/r/qmcgaw/ddns-updater

If you have a Dynamic IP address, you will need a way to keep your Dynamic IP Address insync with your registered domain name. The DNS-Updater container supports MANY DDNS service providers, however we need to use Cloudflare as part of the Authelia zero trust framework for our multifacture authentication, so it makes sense to use Cloudflare to also host your domain and update it with DDNS-Updater. Head over to Cloudflare and register a free account: https://dash.cloudflare.com/sign-up

Once you have registered a free account with Cloudflare, you can transfer your existing domain to Cloudflare with "Domain Registration" --> "Transfer Domains", or you can purchase a new domain inside Cloudflare with "Domain Registration" --> "Purchase Domains".

If you don't want to pay for a domain and want to use a free DDNS domain, then check out the DDNS-Updater documenation and follow the DDNS set up for your preferred option.

Configure the DDNS-Updater by editing the "config.json" file with the details and credentials for your DDNS provider.

```
sudo vi FOLDER_FOR_CONFIGS/ddns-updater/config.json

{
  "settings": [
    {
      "provider": "cloudflare",
      "zone_identifier": "zone id",
      "domain": "your-domain-name.com",
      "host": "@",
      "ttl": 600,
      "token": "yourtoken",
      "ip_version": "ipv4"
    }
  ]
}
```

Restart the DDNS-Updater container, then check the status at: http://docker-host:6500


## Configuring SWAG HTTP / DNS
In order for the Certbot tool inside SWAG to be able to request / issue a digital SSL certificate from Let's Encrypt or ZeroSSL, you need to set up the validation type in ENV.
```
sudo vi docker-compose.env
VALIDATION=dns
DNSPLUGIN=cloudflare
```
If you're using "dns" as the validation process, select the DNS plugin that suits your environment, and make appropriate updates.

DNS plugins are located: "**FOLDER_FOR_CONFIGS/swag/dns-conf/**"

>The domain name you used in "URL" MUST resolve back to your Internet IP address, and your Internet Router / Firewall be set up to forward the ports **80** and **443** to your Docker host IP address, on ports **5080** and **5443** respectively.

Refer to:
 - https://docs.linuxserver.io/general/swag#cert-provider-lets-encrypt-vs-zerossl
 - https://docs.linuxserver.io/general/swag#web-hosting-examples
 - https://docs.linuxserver.io/general/swag#reverse-proxy
 - https://docs.linuxserver.io/general/swag#authorization-method
SWAG has many different plugins available to help validate your "your-domain-name.com" / IP address, via DNS, they are located in the $FOLDER_FOR_CONFIGS/swag/dns-conf folder.
For example, to set up the Cloudflare plugin, edit the following:
```
sudo vi $FOLDER_FOR_CONFIGS/swag/dns-conf/cloudflare.ini
```
**You can then update the ENV file, delete the SWAG container and re-deploy it, to build a new container with the updated configurations.**

###Once your SWAG Server has validated "your-domain-name.com" / IP address, and installed an SSL certificate, the Nginx web server will start working.

###If you have forwarded ports 80 and 443 to the Docker host on 5080 and 5443, then you should be able to access the Nginx web server welcome page from the Internet.

You can use an online remote web browser to check if your site is accessible from the Internet. Go to https://www.browserling.com/ and put in your domain name to test.

>NOTE: All HTTP traffic on port 80 is automatically redirected to HTTPS on port 443, so it helps to have both ports open and redirected.



## Activate Authelia Integration in SWAG Container

How to set up users, passwords and groups in Authelia
https://www.authelia.com/reference/guides/passwords/


https://www.authelia.com/integration/prologue/get-started/


```
sudo vi $FOLDER_FOR_CONFIGS/swag/nginx/authelia-server.conf
sudo vi $FOLDER_FOR_CONFIGS/swag/nginx/authelia-location.conf

sudo vi $FOLDER_FOR_CONFIGS/swag/nginx/site-confs/default.conf
include /config/nginx/authelia-server.conf;

sudo cp $FOLDER_FOR_CONFIGS/swag/nginx/proxy-confs/authelia-server.conf.sample   $FOLDER_FOR_CONFIGS/swag/nginx/proxy-confs/authelia-server.conf
sudo cp $FOLDER_FOR_CONFIGS/swag/nginx/proxy-confs/authelia-location.conf.sample $FOLDER_FOR_CONFIGS/swag/nginx/proxy-confs/authelia-location.conf
```


















## 5 - Configuring the docker applications after they have been deployed
Refer to:
 - https://www.synoforum.com/resources/ultimate-starter-page-1-jellyfin-jellyseerr-nzbget-torrents-and-arr-media-library-stack.184/
 - https://www.synoforum.com/resources/ultimate-starter-page-2-jellyfin-jellyseerr-nzbget-torrents-and-arr-media-library-stack.185/

Follow what is in these pages for now, they will be updated further to include these applications / setup.



# ==*DOCUMENTATION BELOW HAS NOT BEEN COMPLETED.*==
# ==*DOCUMENTATION BELOW HAS NOT BEEN COMPLETED.*==
# ==*DOCUMENTATION BELOW HAS NOT BEEN COMPLETED.*==
# ==*DOCUMENTATION BELOW HAS NOT BEEN COMPLETED.*==
# ==*DOCUMENTATION BELOW HAS NOT BEEN COMPLETED.*==
# ==*DOCUMENTATION BELOW HAS NOT BEEN COMPLETED.*==
# ==*DOCUMENTATION BELOW HAS NOT BEEN COMPLETED.*==
# ==*DOCUMENTATION BELOW HAS NOT BEEN COMPLETED.*==
# ==*DOCUMENTATION BELOW HAS NOT BEEN COMPLETED.*==
# ==*DOCUMENTATION BELOW HAS NOT BEEN COMPLETED.*==

### Document Heimdell integration better
### Document Authelia so the authentication mechanisms are working.... 
One factor / two factor authentication.




## Activate Heimdall Integration in SWAG Container
```
sudo cp $FOLDER_FOR_CONFIGS/swag/nginx/proxy-confs/heimdall.subfolder.conf.sample $FOLDER_FOR_CONFIGS/swag/nginx/proxy-confs/heimdall.subfolder.conf
sudo vi $FOLDER_FOR_CONFIGS/swag/nginx/proxy-confs/heimdall.subfolder.conf

#Enable this line
include /config/nginx/authelia-location.conf;

sudo vi $FOLDER_FOR_CONFIGS/swag/nginx/site-confs/default.conf

```


# THESE ARE ITEMS FOR NOTES ONLY AT THIS POINT

```
Text Editor - Open: 

heimdall.subfolder.conf.sample
sudo vi $FOLDER_FOR_CONFIGS/swag/www/index.html
sudo vi $FOLDER_FOR_CONFIGS/swag/nginx/site-confs/default.conf
sudo vi $FOLDER_FOR_CONFIGS/swag/nginx/site-confs/default.conf
sudo -E vi $FOLDER_FOR_CONFIGS/authelia/
sudo -E vi $FOLDER_FOR_CONFIGS/authelia/

```


https://www.linuxserver.io/blog/zero-trust-hosting-and-reverse-proxy-via-cloudflare-swag-and-authelia

Test...






# THESE ARE ITEMS FOR NOTES ONLY AT THIS POINT



cat /home/geekau/docker/swag/nginx/proxy-confs/sabnzbd.subfolder.conf.sample

/home/geekau/docker/swag/nginx/proxy-confs/sabnzbd.subfolder.conf.sample




$FOLDER_FOR_CONFIGS/swag/
$FOLDER_FOR_CONFIGS/swag/dns-conf/
$FOLDER_FOR_CONFIGS/swag/nginx/proxy-confs/
$FOLDER_FOR_CONFIGS/swag/nginx/proxy-confs/sabnzbd.subfolder.conf.sample
$FOLDER_FOR_CONFIGS/swag/nginx/proxy-confs/sonarr.subfolder.conf.sample
$FOLDER_FOR_CONFIGS/swag/nginx/proxy-confs/sonarr.subdomain.conf.sample
$FOLDER_FOR_CONFIGS/swag/nginx/proxy-confs/sonarr.subfolder.conf.sample
$FOLDER_FOR_CONFIGS/swag/nginx/proxy-confs/sonarr.subdomain.conf.sample
$FOLDER_FOR_CONFIGS/swag/nginx/
$FOLDER_FOR_CONFIGS/swag/nginx/
$FOLDER_FOR_CONFIGS/swag/nginx/proxy.conf
$FOLDER_FOR_CONFIGS/swag/nginx/nginx.conf



sudo -E cp $FOLDER_FOR_CONFIGS/swag/nginx/proxy-confs/sabnzbd.subfolder.conf.sample     $FOLDER_FOR_CONFIGS/swag/nginx/proxy-confs/sabnzbd.subfolder.conf
sudo -E cp $FOLDER_FOR_CONFIGS/swag/nginx/proxy-confs/sonarr.subfolder.conf.sample      $FOLDER_FOR_CONFIGS/swag/nginx/proxy-confs/sonarr.subfolder.conf
ls -la $FOLDER_FOR_CONFIGS/swag/nginx/proxy-confs/*.conf
ls -la $FOLDER_FOR_CONFIGS/swag/nginx/proxy-confs/

mv /mnt/user/appdata/swag/nginx/proxy-confs/sonarr.subdomain.conf.sample /mnt/user/appdata/swag/nginx/proxy-confs/sonarr.subdomain.conf



audiobookshelf.subdomain.conf.sample
audiobookshelf.subfolder.conf.sample
authelia.subdomain.conf.sample
bazarr.subdomain.conf.sample
bazarr.subfolder.conf.sample
filebot.subdomain.conf.sample
filebot.subfolder.conf.sample
jellyfin.subdomain.conf.sample
jellyfin.subfolder.conf.sample
jellyseerr.subdomain.conf.sample
lidarr.subdomain.conf.sample
lidarr.subfolder.conf.sample
mylar.subdomain.conf.sample
mylar.subfolder.conf.sample
portainer.subdomain.conf.sample
portainer.subfolder.conf.sample
prowlarr.subdomain.conf.sample
prowlarr.subfolder.conf.sample
qbittorrent.subdomain.conf.sample
qbittorrent.subfolder.conf.sample
radarr.subdomain.conf.sample
radarr.subfolder.conf.sample
readarr.subdomain.conf.sample
readarr.subfolder.conf.sample
sabnzbd.subdomain.conf.sample
sabnzbd.subfolder.conf.sample
sonarr.subdomain.conf.sample
sonarr.subfolder.conf.sample
tdarr.subdomain.conf.sample






