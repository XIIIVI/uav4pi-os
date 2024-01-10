LICENSE = "MIT"

inherit core-image

IMAGE_INSTALL = " \
    packagegroup-core-boot \
    packagegroup-base-extended \
    packagegroup-core-ssh-openssh \
    bash \
    dbus \
    ${CORE_IMAGE_EXTRA_INSTALL} \
"

IMAGE_FEATURES += "splash"

IMAGE_FEATURES += "${EXTRA_IMAGE_FEATURES}"

# Docker
PREFERRED_PROVIDER_virtual/docker = "docker-moby"

IMAGE_INSTALL += "kernel-image"
IMAGE_INSTALL += "kernel-devicetree"

SDIMG_ROOTFS_TYPE = "ext4"

BBMAASK += "libvorbis"

# Common scripts
IMAGE_INSTALL += "common-scripts"
