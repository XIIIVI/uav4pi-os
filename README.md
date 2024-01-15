[[TOC]]

---
# uav4pi-os
This project provides tools to build embedded Linux for the UAV, the ground station, ...

---
# Pre-requisites

## Required packages

To work, the OS builder requires the following packages to be installed
`sudo install -y dos2unix`

## KAS
The builder uses [KAS](https://github.com/siemens/kas) that should be installed with `pip install kas`.

:warning: With the version of `kas` relying on Docker, the BitBake build fails whereas `kas` installed as described succeeded.

As the builder cannot be executed as root, it is important to create a new user by following those steps:

* Create a new user: `sudo useradd -g users -G docker -m uav`
* Set the password: `sudo passwd uav`
* Use bash when logging: `sudo usermod --shell /bin/bash uav`
* Before launching the builder, log as **uav** `su - uav`

---
# Bibliography
* [Adding docker and docker-compose to a Yocto build](https://hub.mender.io/t/adding-docker-and-docker-compose-to-a-yocto-build/6078)
* [Using kas to reproduce your Yocto builds](https://hub.mender.io/t/using-kas-to-reproduce-your-yocto-builds/6020)