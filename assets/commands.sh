#!/bin/bash
set -euo pipefail

SCRIPT_NAME="$(basename "$0")"
SSH_CONFIG="$TGHS_VAGRANT_SSH_CONFIG"

COMMAND="$SCRIPT_NAME"

if [ "$*" != "" ] ;
then
    ARGS="${*}"
else
    ARGS=""
fi

if [ -z "${DEBUG+x}" ]
then
    DEBUG=0
fi

debug() {
    if [ "${DEBUG}" == "1" ]
    then
        echo >&2 debug: "${*}"
    fi
}

if [ "$SCRIPT_NAME" == "commands.sh" ]
then
    echo >&2 "error: don't call this script directly"
    echo >&2 "error: call one of the other commands"
    exit 1
fi

if [ ! -f "$SSH_CONFIG" ]
then
    echo >&2 "error: unable to find the ssh config for vagrant"
    echo >&2 "error: please edit the script (assets/commands.sh)"
    echo >&2 "error: manually and set the correct path"
fi

run_cmd() {
    local SERVICE="${COMMAND}"
    debug "ssh -F \"${SSH_CONFIG}\" default \"cd /vagrant ; ${SERVICE} ${ARGS}\""
    ssh -F "${SSH_CONFIG}" default "cd /vagrant ; ${CMD} ${SERVICE} ${ARGS}"
    return $?
}

CMD=""


if [ "${SCRIPT_NAME}" == "webpack-dev-server" ]
then
    COMMAND="webpack-dev-server --host 0.0.0.0"
    run_cmd
    exit 0
fi


available_commands=(artisan bower composer gulp npm php webpack)
if ! [[ "${available_commands[@]}" =~ ${SCRIPT_NAME} ]]
then
    echo >&2 "error: the command ${SCRIPT_NAME} is not available"
    exit 1
else
    run_cmd
    exit 0
fi
