# Docker Media Stack

These Docker Compose configurations will help you rapidly deploy all the applications you need in a Docker stack, to operate a Jellyfin, Jellyseerr, Torrent, Usenet, \*ARR Media Library Managers, Reverse Proxy, MFA Authenticated Access, and Tdarr Automated Media Transcoding enabled media stack.

## 1 - Prepare / rename media library if needed:
If you are setting up your media server and media libraries for the very first time, or your media is very poorly named, it is recommended you use Filebot with the following naming standards below, to initially sort all of your media. Otherwise the Media Library Managers and Jellyfin may not be able to identify your media titles, media art, and subtitles, if the original filenames are of a poor standard.

Change "**D:/Storage**" to suit your needs, however use the same disk as the original media, so it is renamed quickly, instead of copied to a different disk or network; this could take a great deal of time to complete depending on size of the libraries / media you are renaming.


**Filebot Renaming Preset String for Series / TV Shows:**
D:/Storage/renaming/series/{ny.colon(' - ').ascii()} [tmdbid-{id}]/Season {s00}/{ny.colon(' - ').ascii()} {s00e00} - {t.ascii()} {" - $hd $vf $vc $ac"}


**Filebot Renaming Preset String for Movies / Adult:**
D:/Storage/renaming/movies/{ny.colon(' - ').ascii()} [imdbid-{imdbid}]/{ny.colon(' - ').ascii()} {" - $hd $vf $vc $ac"}


**Filebot Renaming Preset String for Music / Audio:**
D:/Storage/renaming/music/{artist.upperInitial().ascii()}/{album.upperInitial().ascii()} ({y})/{albumArtist.upperInitial().ascii()} - {album.upperInitial().ascii()} - {pi.pad(3)+' - '} {t.ascii()}


## 2 - Download and edit the "docker-compose.env" file, and update the following sets of variables to suit your requirements.

### Host Data Folders - Will accept Linux, Windows, NAS folder locations
Add the folder locations to the ENV file, where all of your docker / media / downloads will be stored:
>You will need to create the folders, or make sure they already exist.
>Valid choices are Linux, Windows or NAS folder naming conventions.
```
FOLDER_FOR_DOCKER_DATA=/home/ubuntu/docker
FOLDER_FOR_MEDIA=/home/ubuntu/media        <-- These 4 folders need to be on same disk partition / volume
FOLDER_FOR_TORRENTS=/home/ubuntu/torrents  <-- These 4 folders need to be on same disk partition / volume
FOLDER_FOR_USENET=/home/ubuntu/usenet      <-- These 4 folders need to be on same disk partition / volume
FOLDER_FOR_WATCH=/home/ubuntu/watch        <-- These 4 folders need to be on same disk partition / volume
```

### At Linux / Synology terminal, use the "id" command to identify user ID and group ID.
```
sudo id ubuntu
uid=1000(ubuntu) gid=1000(ubuntu) groups=1000(ubuntu)
```
Update the ENV file with these details:
```
PUID=1000	<-- Update this value from "id" command
PGID=1000   <-- Update this value from "id" command
TIMEZONE=Australia/Brisbane
```
Update your local Timezone using this list: [List of tz database time zones - Wikipedia](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones)

### Update your VPN Service Provider details for Gluetun to create VPN tunnel.
Add your VPN service provider details. If you don't have a VPN service provider configure, Gluetun will not establish a secure VPN tunnel, and will not allow any network traffic out onto the Internet.
```
VPN_SERVICE_PROVIDER=VPN provider name
VPN_USERNAME=<username from VPN provider>
VPN_PASSWORD=<password from VPN provider>
SERVER_REGION=<regions supported by VPN provider>
```

## 3 - Set up all of the folders / subfolders / permissions:
### These should match the FOLDER_FOR choices you used above
The commands suit the folders defined above in ENV file... i.e. FOLDER_FOR_DOCKER_DATA, FOLDER_FOR_MEDIA, FOLDER_FOR_TORRENTS etc... Update the script to your needs.

### For Linux commands:
If you used the following Linux folders in the ENV file:
```
FOLDER_FOR_DOCKER_DATA=/home/ubuntu/docker
FOLDER_FOR_MEDIA=/home/ubuntu/media
FOLDER_FOR_TORRENTS=/home/ubuntu/torrents
FOLDER_FOR_USENET=/home/ubuntu/usenet
FOLDER_FOR_WATCH=/home/ubuntu/watch
```
The you would create all of the necessary folders using the following commands:
```
sudo mkdir -p /home/ubuntu/docker/{gluetun,jellyfin,jellyseerr,lidarr,mylar,prowlarr,qbittorrent,radarr,readarr,sabnzbd,sonarr,swag,tdarr,tdarr_transcode_cache,unpackerr,whisparr}
sudo mkdir -p /home/ubuntu/media/{adult,anime,audio,books,comics,movies,music,photos,podcasts,series,software}
sudo mkdir -p /home/ubuntu/usenet/{adult,anime,audio,books,comics,movies,music,prowlarr,podcasts,series,software}
sudo mkdir -p /home/ubuntu/torrents/{adult,anime,audio,books,comics,movies,music,prowlarr,podcasts,series,software}
sudo mkdir -p /home/ubuntu/watch
sudo chmod -R 775 /home/ubuntu/{docker,media,usenet,torrents,watch}
sudo chown -R ubuntu:ubuntu /home/ubuntu/{docker,media,usenet,torrents,watch}
```
### For Window commands:
If you used the following Windows folders in the ENV file:
```
FOLDER_FOR_DOCKER_DATA=D:\Storage\Docker
FOLDER_FOR_MEDIA=D:\Storage\Media
FOLDER_FOR_TORRENTS=D:\Storage\Torrents
FOLDER_FOR_USENET=D:\Storage\Usenet
FOLDER_FOR_WATCH=D:\Storage\Watch
```
The you would create all of the necessary folders using the following commands:
```
FOR /D %I IN (gluetun jellyfin jellyseerr lidarr mylar prowlarr qbittorrent radarr readarr sabnzbd sonarr swag tdarr tdarr_transcode_cache unpackerr whisparr) DO mkdir D:\Storage\Docker\%I
FOR /D %I IN (adult anime audio books comics movies music photos podcasts series software) DO mkdir D:\Storage\Media\%I
FOR /D %I IN (adult anime audio books comics movies music prowlarr podcasts series software) DO mkdir D:\Storage\Torrents\%I
FOR /D %I IN (adult anime audio books comics movies music prowlarr podcasts series software) DO mkdir D:\Storage\Usenet\%I
mkdir D:\Storage\Watch
```

## 4 - Optional - Install Portainer to help manage basic administration functions of your Docker containers:
Portainer should only be used for simple administration
```
docker run -d \
    --name portainer \
    --restart=always \
    -p 8000:8000 \
    -p 9443:9443 \
    -v /var/run/docker.sock:/var/run/docker.sock \
    -v /home/ubuntu/docker/portainer:/data \        Change "/home/ubuntu/docker/portainer" to suite "FOLDER_FOR_DOCKER_DATA/portainer"
    portainer/portainer-ce:latest
```

## 5 - Install the Docker applications individually as you need them.

> **NOTE: Gluetun MUST be installed as the first container**, as it sets up the VPN and the internal Bridge network the other containers will join (media_network).


### Deploy VPN and Internal Docker Bridge "media_network":
```
sudo docker-compose --file docker-compose-gluetun.yaml --project-name media-stack --env-file docker-compose.env up -d
```

>**NOTE:**  =="WARNING: Found orphan containers (gluetun, qbittorrent, sabnzbd, prowlarr, prowlarr) for this project"==

>This WARNING can be safely ignored, as we're loading the project apps one at a time, rather than all in one YAML file.

## Deploy Download Clients:
```
sudo docker-compose --file docker-compose-qbittorrent.yaml --project-name media-stack --env-file docker-compose.env up -d
sudo docker-compose --file docker-compose-prowlarr.yaml    --project-name media-stack --env-file docker-compose.env up -d
```

## Deploy Index Manager and Media Library Managers:
```
sudo docker-compose --file docker-compose-prowlarr.yaml --project-name media-stack --env-file docker-compose.env up -d
sudo docker-compose --file docker-compose-lidarr.yaml   --project-name media-stack --env-file docker-compose.env up -d
sudo docker-compose --file docker-compose-mylar3.yaml   --project-name media-stack --env-file docker-compose.env up -d
sudo docker-compose --file docker-compose-radarr.yaml   --project-name media-stack --env-file docker-compose.env up -d
sudo docker-compose --file docker-compose-readarr.yaml  --project-name media-stack --env-file docker-compose.env up -d
sudo docker-compose --file docker-compose-sonarr.yaml   --project-name media-stack --env-file docker-compose.env up -d
sudo docker-compose --file docker-compose-whisparr.yaml --project-name media-stack --env-file docker-compose.env up -d
```


## Deploy Media Server and Content Request Manager:
```
sudo docker-compose --file docker-compose-jellyfin.yaml     --project-name media-stack --env-file docker-compose.env up -d
sudo docker-compose --file docker-compose-jellyseerr.yaml   --project-name media-stack --env-file docker-compose.env up -d
```

## Deploy Archive Unpacker and Automatic Video Re-encoding:
```
sudo docker-compose --file docker-compose-unpackarr.yaml    --project-name media-stack --env-file docker-compose.env up -d
sudo docker-compose --file docker-compose-tdarr.yaml        --project-name media-stack --env-file docker-compose.env up -d
```

## Deploy Reverse Proxy (with SSL Certbot) and Cloudflare Proxy
```sudo docker-compose --file docker-compose-swag.yaml         --project-name media-stack --env-file docker-compose.env up -d
sudo docker-compose --file docker-compose-flaresolverr.yaml --project-name media-stack --env-file docker-compose.env up -d
```


## Application Portals:

 Portal | Application | Function
-------- | -------- | --------
https://docker-host:9443 | Portainer |GUI Interface for Docker Management
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
http://docker-host:8265|Tdarr|WebUI Automatic Audio/Video Library Transcoding
http://docker-host:6969|Whisparr|(Library Manager - XXX)
http://docker-host:8200|qBittorrent|(Downloader - Torrents)
>**Default qBittorrent Portal Access:**     Username: **admin**     Password: **adminadmin**

>**NOTE: If the qBittorrent portal fails to load with an error message**, it may be due to the themepark module, this can be resolved by editing "FOLDER_FOR_DOCKER_DATA/qbittorrent/qBittorrent/qBittorrent.conf" and changing "WebUI\AlternativeUIEnabled=true" to "false" and restarting qBittorrent.

## For reverse proxy into your network (from the Internet):

 Portal | Application | Function
-------- | -------- | --------
http://your-domain-name.com|SWAG|Reverse Proxy
https://your-domain-name.com|SWAG|Reverse Proxy
> Port 80 will be accessible on the Internet, however it will automatically redirect to HTTPS Port 443.

## 6 - Configuring the docker applications after they have been deployed
Refer to:
1.	https://www.synoforum.com/resources/ultimate-starter-page-1-jellyfin-jellyseerr-nzbget-torrents-and-arr-media-library-stack.184/
2.	https://www.synoforum.com/resources/ultimate-starter-page-2-jellyfin-jellyseerr-nzbget-torrents-and-arr-media-library-stack.185/