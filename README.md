## SHOUTOUT TO <a href=https://github.com/stefanDeveloper>stefanDeveloper</a>
For a manual setup read [ME](./docu/STEFAN.md)

## Overview

This repository provides a Docker stack to easily set up your server with a simple start script

## Table Of Contents

* [Traefik](./traefik/README.md) as a reverse proxy to route your request (mandatory)
* [Wordpress](./blog/README.md) just a simple Wordpress blog page
* [GitLab](./gitlab/README.md) for coding
* [Portainer](./portainer/README.md) helps you to maintain your containers and images
* [Nextcloud](./Nextcloud/README.md) one of my favorite private clouds :heart:
* [Homer](./homer/README.md) just a landing page with links
* [OpenVPN](./openvpn/README.md) is self-explaining
* [Resilio](./resilio/README.md) allows you to sync your data with others, helpful to share backups
* [Seafile](./seafile/README.md) another cloud (not used by me anymore)
* [Matrix](./matrix/README.md) a chat-tool similar to slack, but fully open source
* [Teamspeak](./teamspeak/README.md) a voice over IP service

## Table of Shame

This table includes all services which are not working properly

* [Homer](./homer/README.md)
* [Resilio](./resilio/README.md)
* [Seafile](./seafile/README.md)
* [Matrix](./matrix/README.md)

## Prerequisite

Before running one of the applications, it is advisable to follow the [Prerequisite](./rerequisite/README.md). This guideline helps you to set up your server with some very basic settings, like Fail2Ban.

## Getting Started

```sh
git clone https://github.com/LarsRoman/dodger.git
```
```sh
cd dodger
```
```sh
chmod +x ./start.sh
```
```sh
./start.sh
```

## Troubleshooting

1) Be aware that the docker container may take up to 5minutes to run properly with the reverse proxy
2) Try to access in an incognito browser window
3) Restart the container like `docker restart portainer`
4) Create an issue or push request if you find and/or fixed something

In case the S3 Backup of Gitlab is not working, read the gitlab documentation under Troubleshooting for a manual fix