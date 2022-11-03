These Docker-Compose YAML and ENV files work together to help you rapidly deploy a full VPN encrypted Jellyfin, Jellyseerr, SABnzbd, qBittorrent and *ARR media stack, which can be deployed in only a few minutes on Linux, Windows or Synology NAS Docker hosts.

Ultimate Starter - (PAGE 1) - Jellyfin, Jellyseerr, SABnzbd, Torrents and *ARR Media Library Stack
https://www.synoforum.com/resources/ultimate-starter-page-1-jellyfin-jellyseerr-nzbget-torrents-and-arr-media-library-stack.184/

Ultimate Starter - (PAGE 2) - Jellyfin, Jellyseerr, SABnzbd, Torrents and *ARR Media Library Stack
https://www.synoforum.com/resources/ultimate-starter-page-2-jellyfin-jellyseerr-nzbget-torrents-and-arr-media-library-stack.185/

You can then use the above guides to configure the configuration settings for each of the applications - they are mostly cut-and-paste, to help simplify and speed up the configuration for relatively inexperienced users.

This guide will cover all the steps needed to initially install and configure a secure docker hosted media environment, with all the applications needed to download torrents and Usenet content which you have a right to use in your media library, and allow you to stream the media via a simple web browser, and even stream the media to your Smart TV / Apple TV apps around the house.

The Docker build ensures all network traffic is securely hidden using a VPN, and encrypting ALL traffic in / out of your home network. It can also be used on your Synology NAS, or any other Linux / Windows / MacOS machine running the Docker environment.

With many people owning CDs, DVD, and Blu-ray disks, there is demand to make people's media content more transferrable in their home media systems, so it can be viewed on their personal devices. People also want to be able to put their own home movies / photos onto their media servers, so it too can be freely shared between their devices.

NOTE: This guide is not about, nor promotes, the illegal piracy of digital media content from their respected / licensed owners, it is to allow people to host their own media and enrich it with Internet based metadata, in order to run a private media center in their own homes.

The YAML file should not need any changes, unless you really, really know what you're doing.

The ENV file contains all the settings which gets passed to Docker during the build, and has many options you are able to change, including all the network ports at the bottom of the file.

To get up and running quickly, update the variables below to suit your envirionment, save the ENV file, then build with docker compose... steps are in the guides linked above.

 - Host Data Folders - Will accept Linux, Windows, NAS folders...

FOLDER_FOR_DOCKER_DATA=  <-- This stores persistent configuration settings for all the applications
FOLDER_FOR_MEDIA=		 <-- Use same partition / volume for these file locations
FOLDER_FOR_TORRENTS=     <-- Use same partition / volume for these file locations
FOLDER_FOR_USENET=       <-- Use same partition / volume for these file locations
FOLDER_FOR_WATCH=        <-- Use same partition / volume for these file locations

PUID=
PGID=
TIMEZONE=                <-- Valid options: https://en.wikipedia.org/wiki/List_of_tz_database_time_zones

 - Update these settings from your VPN service provider.
 - Refer here for supported VPN provider settings: https://github.com/qdm12/gluetun/wiki

VPN_SERVICE_PROVIDER=
VPN_USERNAME=
VPN_PASSWORD=
SERVER_REGION=


On the Docker host computer where the FOLDER_FOR_ folder locations are, follow the guide and create all the sub-folders and user permissions for each of these locations.

The Docker-Compose file is now ready to build...

Execute:
docker-compose --file docker-compose-media-stack.yaml --project-name media-stack --env-file docker-compose-media-stack.env up -d


Port numbers can be changed at the bottom of the ENV file.

 - http://localhost:8096     Jellyfin     (Media Player)
 - http://localhost:5055     Jellyseerr   (Content Request Management)
 - http://localhost:8686     Lidarr       (Library Manager - Music)
 - http://localhost:8090     Mylar3       (Library Manager - Comics)
 - http://localhost:9696     Prowlarr     (Index and Search Management)
 - http://localhost:7878     Radarr       (Library Manager - Movies)
 - http://localhost:8787     Readarr      (Library Manager - Books)
 - http://localhost:8100     SABnzbd      (Library Manager - TV Shows)
 - http://localhost:8989     Sonarr       (Library Manager - TV Shows)
 - http://localhost:8200     qBittorrent  (Downloader - Torrents)
 - http://localhost:6969     Whisparr     (Library Manager - XXX)

