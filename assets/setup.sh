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
        # TODO(nicolai): refactor this to use a loop
        echo "alias artisan=\"${SCRIPT_DIR}/artisan\""
        echo "alias bower=\"${SCRIPT_DIR}/bower\""
        echo "alias composer=\"${SCRIPT_DIR}/composer\""
        echo "alias gulp=\"${SCRIPT_DIR}/gulp\""
        echo "alias npm=\"${SCRIPT_DIR}/npm\""
        echo "alias php=\"${SCRIPT_DIR}/php\""
        echo "alias webpack=\"${SCRIPT_DIR}/webpack\""
        echo "alias webpack-dev-server=\"${SCRIPT_DIR}/webpack-dev-server\""
        echo "alias wds=webpack-dev-server"
        echo "alias doco=\"${SCRIPT_DIR}/docker-compose\""
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
