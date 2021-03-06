#!/bin/bash
### Import script helpers ###
source ./scripts/color.sh

### CONFIGURATION ###
NODE_NAME="BOOT_NODE_01" # no spaces!
TESTNET="testnet.json"

REPO_DIR="/home/$USER/dmog-master"
VALIDATOR_DIR="$REPO_DIR/validator-chain"
FULLNODE_DIR="$REPO_DIR/fullnode-chain"
CHAIN_SPEC="$REPO_DIR/chain-spec/$TESTNET"
NODE_TEMPLATE="$REPO_DIR/dmog-node/target/release/dmog"

### FUNCTIONS ###
createValidatorDaemonService() {
    sudo bash -c 'cat > /etc/systemd/system/dmog-validator.service <<EOF
[Unit]
Description=DOT Mogwai Validator

[Service]
WorkingDirectory='$REPO_DIR'

ExecStart='$NODE_TEMPLATE' --base-path '$VALIDATOR_DIR' --chain='$CHAIN_SPEC' --port 30333 --ws-port 9944 --rpc-port 9933 --validator --rpc-methods=Unsafe --name "'$NODE_NAME'" --rpc-cors all
Restart=always
RestartSec=120

[Install]
WantedBy=multi-user.target
EOF'
}

createNodeDaemonService() {
    sudo bash -c 'cat > /etc/systemd/system/dmog-node.service <<EOF
[Unit]
Description=DOT Mogwai Full Node

[Service]
WorkingDirectory='$REPO_DIR'

ExecStart='$NODE_TEMPLATE' --base-path '$FULLNODE_DIR' --chain='$CHAIN_SPEC' --port 30333 --ws-port 9944 --rpc-port 9933  --name "'$NODE_NAME'"
Restart=always
RestartSec=120

[Install]
WantedBy=multi-user.target
EOF'
}

validatorOrNode() {
    echo -n "Validating (v) or Full Node (n)? ([v]/n): "
    read validatingOrNot

    if [ "$validatingOrNot" == "v" ] || [ -z "$validatingOrNot" ]; then
        createValidatorDaemonService
        sudo systemctl enable dmog-validator.service
        sudo systemctl start dmog-validator.service
    else
        createNodeDaemonService
        sudo systemctl enable dmog-node.service
        sudo systemctl start dmog-node.service
    fi
}

setupUbuntu() {
    printf "Enabling validator/node as a service...\n"
    validatorOrNode
}

### EXECUTION ###
printf "${RED}!!! WARNING !!! For testnet use only; potentially unsafe methods used. You've been warned!\n"

if [[ "$OSTYPE" == "linux-gnu" ]]; then
	set -e
	if [ -f /etc/redhat-release ]; then
		echo "Redhat Linux detected."
		echo "This OS is not supported with this script at present. Sorry."
		echo "Please refer to https://github.com/paritytech/substrate for setup information."
		exit 1
	elif [ -f /etc/SuSE-release ]; then
		echo "Suse Linux detected."
		echo "This OS is not supported with this script at present. Sorry."
		echo "Please refer to https://github.com/paritytech/substrate for setup information."
		exit 1
	elif [ -f /etc/arch-release ]; then
		echo "Arch Linux detected."
		export OPENSSL_LIB_DIR="/usr/lib/openssl-1.0";
		export OPENSSL_INCLUDE_DIR="/usr/include/openssl-1.0"
	elif [ -f /etc/mandrake-release ]; then
		echo "Mandrake Linux detected."
		echo "This OS is not supported with this script at present. Sorry."
		echo "Please refer to https://github.com/paritytech/substrate for setup information."
		exit 1
	elif [ -f /etc/debian_version ]; then
		echo "Ubuntu/Debian Linux detected."
        setupUbuntu
	else
		echo "Unknown Linux distribution."
		echo "This OS is not supported with this script at present. Sorry."
		echo "Please refer to https://github.com/paritytech/substrate for setup information."
		exit 1
	fi
elif [[ "$OSTYPE" == "darwin"* ]]; then
	set -e
	echo "${GREEN}Mac OS (Darwin) detected."
    echo "${YELLOW}WIP...come back later" #TODO
elif [[ "$OSTYPE" == "freebsd"* ]]; then
	echo "FreeBSD detected."
	echo "This OS is not supported with this script at present. Sorry."
	echo "Please refer to https://github.com/paritytech/substrate for setup information."
	exit 1
else
	echo "Unknown operating system."
	echo "This OS is not supported with this script at present. Sorry."
	echo "Please refer to https://github.com/paritytech/substrate for setup information."
	exit 1
fi

exit 0
