#!/bin/bash

MISSING_PARAMETER_COUNT=0

#
# install_required_packages
#
install_required_packages() {
    log_info "Installing the required packages"
    sudo apt-get update
    sudo apt-get install -y figlet jq
}

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

#
# check_mandatory_parameter
#	- param1: the variable to check
#
check_mandatory_parameter() {
    local VARIABLE_NAME="${1}"

    if [[ -z "${!VARIABLE_NAME}" ]]; then
        MISSING_PARAMETER_COUNT=$((MISSING_PARAMETER_COUNT + 1))
        log_error "[MISSING] ${1}"
    fi
}

#
# check_all_mandatory_parameters
#   - param*: All the parameters to check
#
check_all_mandatory_parameters() {
    log_info "Checking all the mandatory parameters"
    local MANDATORY_PARAMETER_LIST=("$@")

    for index in "${MANDATORY_PARAMETER_LIST[@]}"; do
        check_mandatory_parameter "${index}"
    done

    if [ ${MISSING_PARAMETER_COUNT} -gt 0 ]; then
        display_help
        exit 1
    else
        log_info "All the required parameters have been defined"
    fi
}

#
# display_file_content
#   - param1: file to display
#
display_file_content() {
    local FILE_TO_CAT="${1}"

    if [ -f "${FILE_TO_CAT}" ]; then
        log_debug "___________________________________ Beginning of $(realpath ${FILE_TO_CAT}) ___________________________________"
        cat "${FILE_TO_CAT}"
        echo
        log_debug "___________________________________ End of $(realpath ${FILE_TO_CAT}) ___________________________________"
    else
        log_error "The file ${FILE_TO_CAT} is missing"
    fi
}

#
# replace_token
#    - param1: token to replace
#    - param2: value of replacement
#
replace_token() {
    local TOKEN="${1}"
    local VALUE="${2}"
    local FILE_TO_PROCESS=($(find . -type f -not -path "./build/**" -not -path "./pipelines/**" -not -path "./layers/**" -not -path "./.git/**" | xargs grep -e "${TOKEN}" | sed 's/:.*$//g'))

    for fileIndex in "${FILE_TO_PROCESS[@]}"; do
        log_warning "[${fileIndex}] Replacing the token ${TOKEN} with the value ${VALUE}"

        if [[ "$(basename ${fileIndex})" != "go.sh" ]]; then
            if [ -f "${fileIndex}" ]; then
                sed -i 's|'${TOKEN}'|'${VALUE}'|g' "${fileIndex}"

                if [[ ${VERBOSE} == "true" ]]; then
                    display_file_content "${fileIndex}"
                fi
            fi
        fi
    done
}

#
# append_text_to_file
#      - param1: message to append,
#      - param2: file the message to append to
#
append_text_to_file() {
    local MESSAGE="${1}"
    local FILE_TO_APPEND_TO="${2}"

    echo "${MESSAGE}" | tee -a "${FILE_TO_APPEND_TO}"
}

#
# clean_up_useless_files
#
clean_up_useless_files() {
    log_info "Cleaning up all the useless files"

    for fileIndex in "${FILE_TO_CLEAN_LIST[@]}"; do
        log_warning "[DELETING] ${fileIndex}"
        rm -Rf "${fileIndex}"
    done
}
