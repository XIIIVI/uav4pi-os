
---
# uav4pi-os
This project provides tools to build embedded Linux for the UAV, the ground station, ...

---
# Pre-requisites

## Required packages

To work, the **OS builder** requires the following packages to be installed
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
# Things to take care when changing the version of Yocto

Upgrading/downgrading the Yocto's version can introduce issues when compiling. This section provides a recap of potential changes.

1) Do not forget to copy/paste the file `meta-uav/recipes-kernel/linux-raspberrypi/linux-raspberrypi_5.15.bbappend`, rename it with the appropriate version number,
2) Update the version of BitBake in the file `src/features/base.yml`

---
# Bibliography
* [Adding docker and docker-compose to a Yocto build](https://hub.mender.io/t/adding-docker-and-docker-compose-to-a-yocto-build/6078)
* [Using kas to reproduce your Yocto builds](https://hub.mender.io/t/using-kas-to-reproduce-your-yocto-builds/6020)