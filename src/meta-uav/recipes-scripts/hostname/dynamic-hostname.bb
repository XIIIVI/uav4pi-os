inherit systemd

LICENSE = "CLOSED"

SRC_URI = " \
    file://hostname.service \
    file://hostname \
"

do_install () {
    install -m 0444 -D ${WORKDIR}/hostname.service ${D}${systemd_system_unitdir}/#-HOSTNAME-#-hostname.service
    install -m 0555 -D ${WORKDIR}/hostname ${D}${libexecdir}/#-HOSTNAME-#-hostname
}

SYSTEMD_SERVICE_${PN} += "#-HOSTNAME-#-hostname.service"