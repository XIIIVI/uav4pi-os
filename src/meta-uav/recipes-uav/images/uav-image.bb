SUMMARY = "Core image recipe used as a base image"
DESCRIPTION = "Directly assign IMAGE_INSTALL and IMAGE_FEATURES for \
               for direct control over image contents."

inherit core-image

require uav-image-common.inc
require uav-user.inc

IMAGE_INSTALL += "strace"

IMAGE_FEATURES:append = " package-management"