SUMMARY = "Common scripts for all the images"
DESCRIPTION = "This recipe installs all the scripts shared between all the images (additional storage management, ...)"

LICENSE = "MIT"
LIC_FILES_CHKSUM = "file://${COMMON_LICENSE_DIR}/MIT;md5=0835ade698e0bcf8506ecda2f7b4f302"

RDEPENDS_${PN} += "bash btrfs-tools multipath-tools parted util-linux"
DEPENDS += "${@ 'i2c-oled-display' if d.getVar('USE_I2C_OLED_DISPLAY') else ''}"
DEPENDS += "${@ 'geekworm-x735' if d.getVar('USE_GEEKWORM_X735_HAT') else ''}"

SRC_URI = " \
    file://setup-external-storage.service \
    file://setup-external-storage.sh \
"

do_install () {
    install -m 0444 -D ${WORKDIR}/setup-external-storage.service ${D}${systemd_system_unitdir}/setup-external-storage.service
    install -m 0555 -D ${WORKDIR}/setup-external-storage.sh ${D}${libexecdir}/setup-external-storage.sh
}

SYSTEMD_SERVICE_${PN} += "setup-external-storage.service"

FILES_${PN} += "${systemd_system_unitdir}/setup-external-storage.service"
FILES_${PN} += "${libexecdir}/setup-external-storage.sh"