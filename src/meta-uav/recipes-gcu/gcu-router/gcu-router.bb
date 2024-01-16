SUMMARY = "Custom Access Point Image"
DESCRIPTION = "Custom Yocto image with Access Point configuration"

LICENSE = "CLOSED"

SRC_URI = " \
    file://hostapd.conf \
"

do_install () {
    install -m 0444 -D ${WORKDIR}/hostapd.conf ${D}/etc/hostapd.conf
}

# Specify the packages to include in the image
IMAGE_INSTALL:append = " \
    hostapd \
    bridge-utils \
    dnsmasq \
    iw \
    "

# Specify the Ethernet interfaces
ETH_INTERFACE1 ?= "eth0"
ETH_INTERFACE2 ?= "eth1"

# Configure WiFi interface (wlan0)
EXTRA_USERS_PARAMS += "\
    echo 'auto wlan0' >> ${IMAGE_ROOTFS}/etc/network/interfaces; \
    echo 'iface wlan0 inet static' >> ${IMAGE_ROOTFS}/etc/network/interfaces; \
    echo '    address 192.168.4.1' >> ${IMAGE_ROOTFS}/etc/network/interfaces; \
    echo '    netmask 255.255.255.0' >> ${IMAGE_ROOTFS}/etc/network/interfaces; \
    "

# Configure Ethernet2 interface (ETH_INTERFACE2)
EXTRA_USERS_PARAMS += "\
    echo 'auto ${ETH_INTERFACE2}' >> ${IMAGE_ROOTFS}/etc/network/interfaces; \
    echo 'iface ${ETH_INTERFACE2} inet static' >> ${IMAGE_ROOTFS}/etc/network/interfaces; \
    echo '    address 192.168.4.2' >> ${IMAGE_ROOTFS}/etc/network/interfaces; \
    echo '    netmask 255.255.255.0' >> ${IMAGE_ROOTFS}/etc/network/interfaces; \
    "

# Configure Ethernet1 interface (ETH_INTERFACE1)
EXTRA_USERS_PARAMS += "\
    echo 'auto ${ETH_INTERFACE1}' >> ${IMAGE_ROOTFS}/etc/network/interfaces; \
    echo 'iface ${ETH_INTERFACE1} inet dhcp' >> ${IMAGE_ROOTFS}/etc/network/interfaces; \
    "

# Configure dnsmasq
EXTRA_USERS_PARAMS += "\
    echo 'interface=wlan0' >> ${IMAGE_ROOTFS}/etc/dnsmasq.conf; \
    echo 'dhcp-range=192.168.4.10,192.168.4.50,12h' >> ${IMAGE_ROOTFS}/etc/dnsmasq.conf; \
    "

# Enable and start dnsmasq during boot
EXTRA_USERS_PARAMS += "\
    echo '/etc/init.d/dnsmasq start' >> ${IMAGE_ROOTFS}/etc/rc.local; \
    "

FILES:${PN} += "/etc/hostapd.conf"
