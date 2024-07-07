# Docker Media Stack: full-vpn_single-yaml

Go to: [https://github.com/geekau/mediastack](https://github.com/geekau/mediastack)

Download the full "mediastack" repository to your computer by selecting "**Code**" --> "**Download Zip**"

Extract the downloaded zip file, then go to the directory which suits your deployment method

Follow the deployment instructions at: [https://MediaStack.Guide](https://MediaStack.Guide)

---

## What is "full-vpn_single-yaml"?

The applications in this directory have been configured so ALL externally bound (Internet) network traffic goes via the Gluetun VPN container - If there is no active VPN connection, then all Internet traffic is halted, for ALL applications. This is the MOST secure network transport solution, as it encrypts the traffic for all of the Docker applications, however it may not be the fastest or most efficient, as all Internet traffic needs to traverse the VPN.

This build has all of the applications combined into a "single" Docker Compose build configuration file (YAML), so all Docker applications / containers are deployed at once, rather than individual deployments.

The single deployment method is ideal for advanced users who are confident their Docker stack configuration  and also allows for easy testing and fault finding when deployment issues occur.

> NOTE: All incoming Internet traffic still goes through Cloudflare DNS and Zero Trust Network Access services, so the network configuration for SWAG (reverse proxy), Authelia, Heimdall and DDNS-Updater applications are not configured to use the Gluetun VPN, as Cloudflare will proxy your inbound Internet traffic directly to your IP Address / Internet connection. SWAG is build to secure all inbound network traffic from the Internet, refer to [https://MediaStack.Guide](https://MediaStack.Guide) for instructions on setting up Internet access to your internal Docker environment.

---

## TL;DR

1. Update settings in `docker-compose.env` to suit your VPN account, local networking, and location of Docker Configuration Files / Media Storage

2. Deploy entire Docker environment using the `docker-compose-media-stack.yaml` Docker Compose file

3. Import `MediaStack.Guide Applications` bookmarks into your web browser, to easily access each application
