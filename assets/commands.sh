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

    # This command is not in the PATH, but lies in the project folder.
    # TODO(nicolai): Figure out a better way to do this.
    #                PATH="/vagrant:$PATH" is not as easy as it seems.
    if [ "$SERVICE" == "artisan" ]
    then
        SERVICE="./artisan"
    fi

    local SSHRET
    SSHRET=0

    debug "ssh -F \"${SSH_CONFIG}\" default \"cd /vagrant ; ${SERVICE} ${ARGS}\""
    ssh -t -F "${SSH_CONFIG}" default "cd /vagrant ; ${SERVICE} ${ARGS} ; ERR=\$? ;" \
        "test \$ERR = 0 || printf '\n%s\n' \"${SERVICE} returned: \$ERR\"" \
        || SSHRET=$?

    if [ $SSHRET == 255 ]
    then
        echo >&2 "error: could not connect"
        echo >&2 "error: is Vagrant running?"
    fi

    return $?
}

CMD=""


if [ "${SCRIPT_NAME}" == "webpack-dev-server" ]
then
    COMMAND="webpack-dev-server --host 0.0.0.0"
    run_cmd
    exit 0
fi

if [ "${SCRIPT_NAME}" == "ev" ]
then
    COMMAND=""
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
