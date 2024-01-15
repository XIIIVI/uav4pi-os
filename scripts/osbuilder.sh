#!/bin/bash

# shellcheck source=./scripts/commons.sh
source ./scripts/commons.sh

#
# display_help
#
display_help() {
    log_debug "Usage: ${0} [--build|clean] (build (default) the image or clean the repository)"
    log_debug "            [--data-dir <Folder> (Set the folder containing user's data)]"
    log_debug "            [--delivery-dir <Folder where the images will be copied at the end of the process>]"
    log_debug "            --flavour <one of the configuration folder src/flavours>"
    log_debug "            [--hostname <Hostname prefix>]"
    log_debug "            [--machine raspberrypi-cm | raspberrypi-cm3 | raspberrypi | raspberrypi0-wifi | raspberrypi0 | raspberrypi2 | raspberrypi3-64 | raspberrypi3 | raspberrypi4-64 | raspberrypi4] (default raspberrypi4-64)"
    log_debug "            [--refspec <Version of Yocto to use> (default: nanbield)]"
    log_debug "            [--root-password <Password of the root user>]"
    log_debug "            [--user-login <Login of the user to create> (default uav)]"
    log_debug "            [--user-password <Password of the user to create>]"
    log_debug "            [--verbose (Display the content of the files where token have been replaced)]"
    log_debug "            [--version <Version of the image>]"
    log_debug "            [--workdir <Folder where cache, temp files, ... are stored AND re-used>]"
}

#
# display_settings
#
display_settings() {
    log_debug "S E T T I N G S"
    log_debug "COMMAND              : ${COMMAND}"
    log_debug "CUSTOM_HOSTNAME      : ${CUSTOM_HOSTNAME}"
    log_debug "DIR_DIST             : ${DIR_DIST}"
    log_debug "DISTRO               : ${DISTRO}"
    log_debug "DISTRO_VERSION       : ${DISTRO_VERSION}"
    log_debug "FLAVOUR              : ${FLAVOUR}"
    log_debug "MACHINE              : ${MACHINE}"
    log_debug "REF_SPEC             : ${REF_SPEC}"
    log_debug "ROOT_PASSWORD        : ${ROOT_PASSWORD}"
    log_debug "USER_LOGIN           : ${USER_LOGIN}"
    log_debug "USER_PASSWORD        : ${USER_PASSWORD}"
    log_debug "VERBOSE              : ${VERBOSE}"
}

#
# replace_all_tokens
#	- param1: the list of token to replace
#
replace_all_tokens() {
    local TOKEN_LIST_ARG=("$@")

    log_info "\t- Replacing the tokens"
    for ITEM in "${TOKEN_LIST_ARG[@]}"; do
        replace_token "#-${ITEM}-#" "$(eval echo "\$$ITEM")"
    done
}

#
# load_flavour_settings
#   - param1: flavour to generate
#
load_flavour_settings() {
    local SETTING_FILE_ARG="${1}"
    local TMP_FILE="$(mktemp)"

    log_debug "\t- Preparing the environment from the file ${SETTING_FILE_ARG}"
    cp "${SETTING_FILE_ARG}" "${TMP_FILE}"
    echo "" >>"${TMP_FILE}"
    dos2unix "${TMP_FILE}"

    # Check if the file exists
    if [ -f "${SETTING_FILE_ARG}" ]; then
        # Read the file line by line
        while IFS='=' read -r KEY VALUE; do
            # Set environment variable
            export "${KEY}=${VALUE}"

            TOKEN_LIST+=("${KEY}")

            log_debug "\t\t- ${KEY}=${VALUE}"
        done <"${TMP_FILE}"

        log_debug "\t- Environment variables have been initialized."

    else
        log_error "\t- The settings file is missing: ${SETTING_FILE_ARG}"
    fi
}

#
# build_with_kas
#   - param1: flavour to generate
#   - param2: workdir
#
build_with_kas() {
    local FLAVOUR_ARG="${1}"
    local WORK_DIR_ARG="${2}"
    local TMP_FILE="$(mktemp)"
    local FILE_FLAVOUR="${WORK_DIR_ARG}/flavours/${FLAVOUR_ARG}/flavour"

    log_debug "\t- Generating the kas configuration file ${WORK_DIR_ARG}/${FLAVOUR_ARG}.yml from the flavour ${FILE_FLAVOUR}"
    cp "${FILE_FLAVOUR}" "${TMP_FILE}"
    echo "" >>"${TMP_FILE}"
    dos2unix "${TMP_FILE}"

    # Check if the file exists
    if [ -f "${FILE_FLAVOUR}" ]; then
        cat <<EOF >"${WORK_DIR_ARG}/${FLAVOUR_ARG}.yml"
header:
  version: 11
  includes:
  - features/base.yml
  - features/local.yml
EOF

        # Read the file line by line
        while IFS='=' read -r LINE; do
            log_debug "\t\t- Adding the feature ${LINE}"
            echo "  - features/${LINE}.yml" >>"${WORK_DIR_ARG}/${FLAVOUR_ARG}.yml"
        done <"${TMP_FILE}"

        cat <<EOF >>"${WORK_DIR_ARG}/${FLAVOUR_ARG}.yml"

repos:
  meta-uav:
    path: meta-uav

distro: ${DISTRO}

target:
  - ${FLAVOUR_ARG}

machine: ${MACHINE}
EOF

        cat "${WORK_DIR_ARG}/${FLAVOUR_ARG}.yml"
        log_debug "\t- Building the image with kas using the configuration file ${WORK_DIR_ARG}/${FLAVOUR_ARG}.yml"
        kas build "${WORK_DIR_ARG}/${FLAVOUR_ARG}.yml"
    else
        log_error "\t- The flavour file is missing: ${FILE_FLAVOUR}"
    fi
}

#
# configure_yocto
#   - param1: flavour to generate
#   - param2: workdir
#
configure_yocto() {
    local FLAVOUR_ARG="${1}"
    local WORK_DIR_ARG="${2}"
    local CONF_DISTRO_DIR="${WORK_DIR_ARG}/meta-uav/conf/distro"

    log_debug "\t- Configuring the distro configuration file ${CONF_DISTRO_DIR}/${DISTRO}.conf for Yocto"
    cat <<EOF >>"${CONF_DISTRO_DIR}/${DISTRO}".conf
require conf/distro/commons.conf

DISTRO = "${DISTRO}"
DISTRO_NAME = "${DISTRO_NAME:=${DISTRO}}"
DISTRO_VERSION = "${DISTRO_VERSION}"
DISTRO_CODENAME = "${DISTRO_CODENAME:=${DISTRO}}"
EOF

    log_debug "\t- Creating the recipe for the flavour ${FLAVOUR_ARG} in ${WORK_DIR_ARG}/meta-uav/recipes-${FLAVOUR_ARG}/images"
    mkdir -p "${WORK_DIR_ARG}/meta-uav/recipes-${FLAVOUR_ARG}/images"

    # Creating the recipe
    log_debug "\t\t- Creating the file ${WORK_DIR_ARG}/meta-uav/recipes-${FLAVOUR_ARG}/images/${FLAVOUR_ARG}.bb"
    cat <<EOF >>"${WORK_DIR_ARG}/meta-uav/recipes-${FLAVOUR_ARG}/images/${FLAVOUR_ARG}.bb"
SUMMARY = "Core image recipe used as a base image for ${FLAVOUR_ARG}"
DESCRIPTION = "Directly assign IMAGE_INSTALL and IMAGE_FEATURES for \
               for direct control over image contents."

require ${FLAVOUR_ARG}-common.inc
require ${FLAVOUR_ARG}-user.inc

IMAGE_INSTALL += "strace"

IMAGE_FEATURES:append = " package-management"
EOF

    # Creating the common inc file
    log_debug "\t\t- Creating the file ${WORK_DIR_ARG}/meta-uav/recipes-${FLAVOUR_ARG}/images/${FLAVOUR_ARG}-common.inc"
    cat <<EOF >>"${WORK_DIR_ARG}/meta-uav/recipes-${FLAVOUR_ARG}/images/${FLAVOUR_ARG}-common.inc"
LICENSE = "MIT"

inherit core-image

IMAGE_INSTALL = " \
    packagegroup-core-boot \
    packagegroup-base-extended \
    packagegroup-core-ssh-openssh \
    bash \
    \${CORE_IMAGE_EXTRA_INSTALL} \
"

IMAGE_FEATURES += "splash"

IMAGE_FEATURES += "\${EXTRA_IMAGE_FEATURES}"

SDIMG_ROOTFS_TYPE = "ext4"

# Common scripts
IMAGE_INSTALL += "common-scripts"
EOF

    # Creating the user inc file
    log_debug "\t\t- Creating the file ${WORK_DIR_ARG}/meta-uav/recipes-${FLAVOUR_ARG}/images/${FLAVOUR_ARG}-user.inc"
    cat <<EOF >>"${WORK_DIR_ARG}/meta-uav/recipes-${FLAVOUR_ARG}/images/${FLAVOUR_ARG}-user.inc"
inherit extrausers

# Use openssl passwd -6 to hash a password.
#
# Example: openssl passwd -6 test
#
# Dollar signs ($) should be escaped with backslash characters (\).

EXTRA_USERS_PARAMS += " useradd ${USER_LOGIN};"
EXTRA_USERS_PARAMS += " usermod -p '${USER_PASSWORD}' ${USER_LOGIN}; "
# EXTRA_USERS_PARAMS += " usermod -aG sudo ${USER_LOGIN}; "
EXTRA_USERS_PARAMS += " usermod -p '${ROOT_PASSWORD}' root; "
EOF
}

#
# build_os_image
#   - param1: the flavour to generate
#   - param2: the folder where to store the images
#
build_os_image() {
    local FLAVOUR_ARG="${1}"
    local DIR_DIST_ARG="${2}"

    if [ -f "${BASEDIR}/src/flavours/${FLAVOUR_ARG}/flavour" ]; then
        local WORK_DIR=${WORK_DIR:="$(mktemp -d)"}
        local DISTRO="${FLAVOUR_ARG//[^[:alnum:]]/}os"
        local DIR_DELIVERY="/tmp/${DISTRO}/delivery"
        local TOKEN_LIST=("DIR_DATA" "DIR_DELIVERY" "DISTRO" "DISTRO_VERSION" "MACHINE" "REF_SPEC" "FLAVOUR" "USER_PASSWORD" "USER_LOGIN" "WORK_DIR")
        local DIR_IMAGE_DELIVERY="${DIR_DIST_ARG}/${FLAVOUR_ARG}"

        rm -Rf "${DIR_DELIVERY}"
        mkdir -p "${DIR_DELIVERY}"

        log_info "\n+--------------------------------------------------------------------+"
        log_info "| Generating the flavour ${FLAVOUR_ARG} in ${WORK_DIR}"
        log_info "+--------------------------------------------------------------------+"
        log_debug "\t- Preparing the flavour"
        cp -R "${BASEDIR}"/src/** "${WORK_DIR}/"
        cd "${WORK_DIR}" || exit

        FILE_GENERATED_IMAGE="${FLAVOUR_ARG}-${MACHINE}-${DISTRO_VERSION}.wic.bz2"

        log_debug "\t- Cleaning previous deliveries for ${FILE_GENERATED_IMAGE}"
        rm -Rf "${DIR_DELIVERY:?}/${FILE_GENERATED_IMAGE}"

        load_flavour_settings "${WORK_DIR}/flavours/${FLAVOUR_ARG}/settings" "${TOKEN_LIST[@]}"
        log_debug "\t- Here is the update list of token ${TOKEN_LIST[*]}"

        configure_yocto "${FLAVOUR_ARG}" "${WORK_DIR}"
        replace_all_tokens "${TOKEN_LIST[@]}"

        build_with_kas "${FLAVOUR_ARG}" "${WORK_DIR}"

        if [ -n "$(find "${DIR_DELIVERY}-glibc/deploy/images/${MACHINE}/" -maxdepth 1 -type l -name "${FLAVOUR_ARG}-${MACHINE}.*")" ]; then
            mkdir -p "${DIR_IMAGE_DELIVERY}"

            cp "${DIR_DELIVERY}-glibc/deploy/images/${MACHINE}/${FLAVOUR_ARG}-${MACHINE}".* "${DIR_IMAGE_DELIVERY}/"
            git reset --hard
            log_debug "\t- [DONE] The generated images are available in ${DIR_IMAGE_DELIVERY}"
            ls -alh "${DIR_IMAGE_DELIVERY}"
        else
            log_error "\t- [ERROR] Found no images in  ${DIR_DELIVERY}-glibc/deploy/images/${MACHINE}"
        fi
    else
        log_error "The flavour ${WORK_DIR}/flavours/${FLAVOUR_ARG}/flavour does not exist"
    fi
}

#
# main
#
main() {
    # Parses the parameters
    while (("$#")); do
        case "$1" in
        --build)
            COMMAND="build"
            shift # past argument
            ;;
        --clean)
            COMMAND="clean"
            shift # past argument
            ;;
        --delivery-dir)
            DIR_DIST="${2}"
            shift # past argument
            shift # past value
            ;;
        --flavour)
            FLAVOUR="${2,,}"
            shift # past argument
            shift # past value
            ;;
        --machine)
            MACHINE="${2,,}"
            shift # past argument
            shift # past value
            ;;
        --refspec)
            REF_SPEC="${2,,}"
            shift # past argument
            shift # past value
            ;;
        --root-password)
            ROOT_PASSWORD="${2}"
            shift # past argument
            shift # past value

            if [ ${#ROOT_PASSWORD} -gt 8 ]; then
                log_error "The length of the root password cannot exceed 8 characters"
                exit
            elif [ ${#ROOT_PASSWORD} -lt 4 ]; then
                log_error "The root password MUST be greater than 3 characters"
                exit
            fi
            ;;
        --user-login)
            USER_LOGIN="${2,,}"
            shift # past argument
            shift # past value
            ;;
        --user-password)
            USER_PASSWORD="${2}"
            shift # past argument
            shift # past value

            if [ ${#USER_PASSWORD} -gt 8 ]; then
                log_error "The length of the user password cannot exceed 8 characters"
                exit
            elif [ ${#USER_PASSWORD} -lt 4 ]; then
                log_error "The user password MUST be greater than 3 characters"
                exit
            fi
            ;;
        --verbose)
            VERBOSE="true"
            shift # past argument
            ;;
        --version)
            DISTRO_VERSION="${2}"
            shift # past argument
            shift # past value
            ;;
        --workdir)
            DIR_WORK="${2}"
            shift # past argument
            shift # past value
            ;;
        -h | --help)
            display_help
            shift # past argument
            exit 1
            ;;
        --) # end argument parsing
            shift
            break
            ;;
        -* | --*=) # unsupported flags
            log_error "Error: Unsupported flag $1" >&2
            display_help
            exit 1
            ;;
        *) # preserve positional arguments
            shift
            ;;
        esac
    done

    COMMAND=${COMMAND:="build"}
    DEVOPS=${DEVOPS:="false"}
    DIR_DATA=${DIR_DATA:="/datadrive"}
    DISTRO_VERSION=${DISTRO_VERSION:="#-UNKNOWN_VERSION-#"}
    MACHINE=${MACHINE:="raspberrypi4-64"}
    REF_SPEC=${REF_SPEC:="nanbield"}
    VERBOSE=${VERBOSE:="false"}
    ROOT_PASSWORD=${ROOT_PASSWORD:="Th3B0ss!"}
    USER_LOGIN=${USER_LOGIN:="uav"}
    USER_PASSWORD=${USER_PASSWORD:="JuR1_39"}
    CUSTOM_HOSTNAME=${CUSTOM_HOSTNAME:="${FLAVOUR}"}
    BASEDIR="${PWD}"
    DIR_WORK=${DIR_WORK:="${BASEDIR}"}
    DISTRO="${DISTRO:=${FLAVOUR//[^[:alnum:]]/}os}"
    DIR_DIST="${DIR_DIST:=${BASEDIR}/dist}"
    TMP_BANNER=$(mktemp).banner

    # Extract the version number
    GITVERSION_CONTENT=$(docker run --rm -v "$(pwd):/repo" gittools/gitversion:5.6.10-alpine.3.12-x64-3.1 /repo)

    if [ $? -eq 0 ]; then
        log_warning "[EXTRACTING] Using GitVersion to extract the version number of the distro"
        DISTRO_VERSION=$(echo "${GITVERSION_CONTENT}" | jq '.LegacySemVer' | sed 's/"//g')
    else
        log_error "[ERROR] Failing using GitVersion, the distro version is ${DISTRO_VERSION}"
    fi

    cp ./scripts/builder.banner "${TMP_BANNER}"
    sed -i "s/#-DISTRO_VERSION-#/${DISTRO_VERSION}/g" "${TMP_BANNER}"
    cat "${TMP_BANNER}"
    display_settings

    case "${COMMAND}" in
    build)
        check_all_mandatory_parameters "FLAVOUR"
        log_info "Cleaning the distribution folder ${DIR_DIST}"
        rm -Rf "${DIR_DIST}"
        mkdir -p "${DIR_DIST}"

        build_os_image "${FLAVOUR}" "${DIR_DIST}"
        ;;

    clean)
        log_info "Cleaning the environment"
        kas clean
        ;;
    *)
        log_error "Missing command (--build, --clean)"
        ;;
    esac
}

time main "$@"
