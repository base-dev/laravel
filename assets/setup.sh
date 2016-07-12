#!/bin/bash

main() {
    local SCRIPT_DIR \
          ENV_FILE \
          PROJECT_ROOT

    SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
    PROJECT_ROOT=$(realpath "$SCRIPT_DIR/..")
    ENV_FILE="$PROJECT_ROOT"/.zenv

    cd "$SCRIPT_DIR" || exit 1
    
    # Remove .env-file if it exists
    echo "Attempting to remove old .zenv file"
    rm -f "$ENV_FILE" || exit 1

    vagrant_setup
}

vagrant_setup() {
    if ! which vagrant &>/dev/null
    then
        echo >&2 "error: couldn't run command 'vagrant'"
        echo >&2 "error: You must have vagrant installed"
        echo >&2 "error: to run the vagrant-setup"
        exit 1
    fi

    echo "Creating new .env file with aliases"
    {
        echo "export TGHS_PROJECT_ROOT=\"${PROJECT_ROOT}\""
        echo "export TGHS_VAGRANT_SSH_CONFIG=\"${SCRIPT_DIR}/ssh-config\""
        echo

        # TODO(nicolai): define somewhere more logical (these are used in commands.sh too)
        declare -a _commands=(artisan bower composer gulp npm php webpack webpack-dev-server)

        for _cmd in "${_commands[@]}"
        do
            echo "alias $_cmd=\"${SCRIPT_DIR}/$_cmd\""
        done
        unset _commands
        unset _cmd

        if [[  "${_commands[@]}" =~ "webpack-dev-server" ]]
        then
            echo "alias wds=webpack-dev-server"
        fi

    } >> "$ENV_FILE"

    # generate ssh-config
    echo "Generating ssh-config for Vagrant"

    if ! vagrant ssh -c "true;" &>/dev/null
    then
        echo >&2 "error: couldn't create ssh-config."
        echo >&2 "error: vagrant must be running."
        echo >&2 "error: try issuing a \`vagrant up\`"
        exit 1
    fi

    cat <<EOF >ssh-config
# vim:filetype=sshconfig
#
# This file is file is generated  by the setup.sh script
$(vagrant ssh-config)
  ControlMaster auto
  ControlPath ${SCRIPT_DIR}/ssh_control_master-%r@%h:%p
EOF
}

main

echo "Done!"
