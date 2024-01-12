inherit systemd

LICENSE = "CLOSED"

SRC_URI = " \
    file://hostname.service \
    file://hostname \
"

do_install () {
    install -m 0444 -D ${WORKDIR}/hostname.service ${D}${systemd_system_unitdir}/#-PREDEFINED_HOSTNAME-#-hostname.service
    install -m 0555 -D ${WORKDIR}/hostname ${D}${libexecdir}/#-PREDEFINED_HOSTNAME-#-hostname
}

SYSTEMD_SERVICE_${PN} += "#-PREDEFINED_HOSTNAME-#-hostname.service"

FILES:${PN} += "${systemd_system_unitdir}/#-PREDEFINED_HOSTNAME-#-hostname.service"
FILES:${PN} += "${libexecdir}/#-PREDEFINED_HOSTNAME-#-hostname"

SYSTEMD_AUTO_ENABLE = "enable"