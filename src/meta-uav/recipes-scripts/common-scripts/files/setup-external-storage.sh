#!/bin/bash

#
# log_section
#   - param: message
#
log_section() {
    if [[ ${DEVOPS} == "true" ]]; then
        echo "##[section]${1}"
    else
        echo -e "\e[34m${1}\e[97m"
    fi
}

#
# log_error
#   - param: message
#
log_error() {
    if [[ ${DEVOPS} == "true" ]]; then
        echo "##vso[task.logissue type=error] ${1}"
    else
        echo -e "\e[91m${1}\e[97m"
    fi
}

#
# log_warning
#   - param: message
#
log_warning() {
    if [[ ${DEVOPS} == "true" ]]; then
        echo "##vso[task.logissue type=warning] ${1}"
    else
        echo -e "\e[33m${1}\e[97m"
    fi
}

#
# log_info
#   - param: message
#
log_info() {
    if [[ ${DEVOPS} == "true" ]]; then
        echo "##[command]${1}"
    else
        echo -e "\e[92m${1}\e[97m"
    fi
}

#
# log_debug
#   - param: message
#
log_debug() {
    if [[ ${DEVOPS} == "true" ]]; then
        echo "##[debug]${1}"
    else
        echo -e "\e[95m${1}\e[97m"
    fi
}

STORAGE_TYPE="${1}"

STORAGE_NAME=$(lsblk -o NAME | grep -i "${STORAGE_TYPE}")

if [ -n "${STORAGE_NAME}" ]; then
    log_info "Initializing the storage ${STORAGE_NAME}"
    DIR_DATA_FOLDER=#-DIR_DATA-#

    parted "/dev/${STORAGE_NAME}" --script mklabel gpt mkpart xfspart xfs 0% 100%
    mkfs.xfs -f "/dev/${STORAGE_NAME}"
    partprobe "/dev/${STORAGE_NAME}"

    log_info "Mounting the disk ${STORAGE_NAME} on data folder ${DIR_DATA_FOLDER}"
    mkdir -p "${DIR_DATA_FOLDER}"
    mount "/dev/${STORAGE_NAME}" "${DIR_DATA_FOLDER}"
    VIRGIN_DISK_UUID=$(blkid | grep "${STORAGE_NAME}" | awk '{ print $2 }' | sed 's/=/ /g' | awk '{ print $2 }' | sed 's/"//g')

    log_info "Associating the UUID ${VIRGIN_DISK_UUID} with the folder ${DIR_DATA_FOLDER} in /etc/fstab"
    echo "UUID=${VIRGIN_DISK_UUID}   ${DIR_DATA_FOLDER}   xfs   defaults,discard   1   2" | tee -a /etc/fstab

    log_info "Making the user #-USER_LOGIN-# owner of the folder ${DIR_DATA_FOLDER}"
    chown -R #-USER_LOGIN-#:#-USER_LOGIN-# "${DIR_DATA_FOLDER}"
else
    log_error "No storage of type ${STORAGE_TYPE} has been found ..."
fi
