#!/bin/bash

# shellcheck source=./scripts/commons.sh
source ./scripts/commons.sh

#
# install_kas
#
install_kas() {
    log_info "[INSTALLING] Kas in ${WORK_DIR}/kas"

    rm -Rf "${WORK_DIR}"/kas
    git clone https://github.com/siemens/kas "${WORK_DIR}"/kas

    export PATH=${WORK_DIR}/kas/kas-docker:${PATH}
}

#
# display_help
#
display_help() {
    log_debug "Usage: ${0} [--build|clean] (build (default) the image or clean the repository)"
    log_debug "            [--data-dir <Folder> (Set the folder containing user's data)]"
    log_debug "            --image <one of the file .flv in src/flavours>"
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
    log_debug "DISTRO               : ${DISTRO}"
    log_debug "DISTRO_VERSION       : ${DISTRO_VERSION}"
    log_debug "FLAVOUR              : ${FLAVOUR}"
    log_debug "MACHINE              : ${MACHINE}"
    log_debug "REF_SPEC             : ${REF_SPEC}"
    log_debug "ROOT_PASSWORD        : ${ROOT_PASSWORD}"
    log_debug "TARGET_IMAGE         : ${TARGET_IMAGE}"
    log_debug "USER_LOGIN           : ${USER_LOGIN}"
    log_debug "USER_PASSWORD        : ${USER_PASSWORD}"
    log_debug "VERBOSE              : ${VERBOSE}"
}

#
# replace_all_tokens
#	- param1: distro'name
#   - param2: distro's version
#	- param3: image to generate
#   - param4: folder storing the user's data
#	- param5: targetted machine
#	- param6: ref_spec (Yocto's version)
#	- param7: hostname
#	- param8: root's password
#	- param9: user's login
#	- param10: user's password
#   - param11: use Geekworm X735
#
replace_all_tokens() {
    log_info "Replacing the tokens"
    replace_token "#-DISTRO-#" "${DISTRO}"
    replace_token "#-MACHINE-#" "${MACHINE}"
    replace_token "#-REF_SPEC-#" "${REF_SPEC}"
    replace_token "#-TARGET_IMAGE-#" "${TARGET_IMAGE}"
    replace_token "#-WORK_DIR-#" "${WORK_DIR}"
}

#
# build_os_image
#
build_os_image() {
    check_all_mandatory_parameters "TARGET_IMAGE"

    if [ -f "${WORK_DIR}/flavours/${TARGET_IMAGE}.flv" ]; then
        cd "${WORK_DIR}" || exit

        KAS_FILES+=":$(awk '{printf "'"${WORK_DIR}"'/kas-config/%s.yml", $0; if (NR!=1) printf ":"} END{print ""}' "${WORK_DIR}/flavours/${TARGET_IMAGE}.flv")"
        log_info "Updating the list of KAS files to use based on the flavour ${TARGET_IMAGE}: ${KAS_FILES}"

        display_settings

        log_info "Preparing the delivery folder ${DIR_DELIVERY}"
        DIR_DELIVERY="${BASEDIR}/delivery/${TARGET_IMAGE}"

        mkdir -p "${DIR_DELIVERY}"

        FILE_GENERATED_IMAGE="${TARGET_IMAGE}-${MACHINE}-${DISTRO_VERSION}.wic.bz2"

        log_info "Cleaning previous deliveries for ${FILE_GENERATED_IMAGE}"
        rm -Rf "${DIR_DELIVERY:?}/${FILE_GENERATED_IMAGE}"

        log_info "Preparing the environment"
        replace_all_tokens

        log_info "Building the image ${TARGET_IMAGE} (${DISTRO}) with the following configuration files ${KAS_FILES}"
        export KAS_ALLOW_ROOT=yes && kas/kas-docker build "${KAS_FILES}"

        cp "${DIR_WORK}/build/tmp/deploy/images/${MACHINE}/${TARGET_IMAGE}-${MACHINE}.wic.bz2" "${DIR_DELIVERY}/${FILE_GENERATED_IMAGE}" &&
            git reset --hard &&
            log_info "The generated image ${FILE_GENERATED_IMAGE} is available in ${DIR_DELIVERY}"
        ls -alh "${DIR_DELIVERY}"

        if [ -f "${DIR_DELIVERY}/${FILE_GENERATED_IMAGE}" ]; then
            log_info "Cleaning, please wait ..."
            kas/kas-docker clean
        fi
    else
        log_error "The image ${TARGET_IMAGE} does not exist"
    fi
}

#
# main
#
main() {
    install_required_packages

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
        --flavour)
            FLAVOUR="${2,,}"
            shift # past argument
            shift # past value
            ;;
        --image)
            TARGET_IMAGE="${2,,}"
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
    DIR_WORK=${DIR_WORK:="${BASEDIR}"}
    DISTRO_VERSION=${DISTRO_VERSION:="#-UNKNOWN_VERSION-#"}
    MACHINE=${MACHINE:="raspberrypi4-64"}
    REF_SPEC=${REF_SPEC:="kirkstone"}
    VERBOSE=${VERBOSE:="false"}
    ROOT_PASSWORD=${ROOT_PASSWORD:="Th3B0ss!"}
    USER_LOGIN=${USER_LOGIN:="raspberry"}
    USER_PASSWORD=${USER_PASSWORD:="JuR1_39"}
    CUSTOM_HOSTNAME=${CUSTOM_HOSTNAME:="${TARGET_IMAGE}"}
    WORK_DIR=${WORK_DIR:="$(mktemp -d)"}
    BASEDIR="${WORK_DIR}"
    KAS_FILES="${WORK_DIR}/kas-config/preferred_versions.yml:${WORK_DIR}/kas-config/local.yml:${WORK_DIR}/kas-config/poky.yml:${WORK_DIR}/kas-config/global.yml"
    DISTRO="${TARGET_IMAGE}"

    log_info "Setting up the environment"
    install_kas
    cp -R ./src/* "${WORK_DIR}/"

    # Extract the version number
    GITVERSION_CONTENT=$(docker run --rm -v "$(pwd):/repo" gittools/gitversion:5.6.10-alpine.3.12-x64-3.1 /repo)

    if [ $? -eq 0 ]; then
        log_warning "[EXTRACTING] Using GitVersion to extract the version number of the distro"
        DISTRO_VERSION=$(echo "${GITVERSION_CONTENT}" | jq '.LegacySemVer' | sed 's/"//g')
    else
        log_error "[ERROR] Failing using GitVersion, the distro version is ${DISTRO_VERSION}"
    fi

    case "${COMMAND}" in
    build)
        build_os_image
        ;;

    clean)
        log_info "Cleaning the environment"
        kas/kas-docker clean
        ;;
    *)
        log_error "Missing command (--build, --clean)"
        ;;
    esac
}

time main "$@"
