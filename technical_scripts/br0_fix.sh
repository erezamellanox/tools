#!/bin/bash

TRUSTED_IF_NAME=""
TRUSTED_IP_PREFIX=""
THIS_FILE="$(basename "$0")"
IFCFGS_PATH="/etc/sysconfig/network-scripts/"

print_help() {
	echo -e "Usage:"
	echo -e "./$THIS_FILE -t|--trusted_if_name TRUSTED_INTERFACE_NAME"
	echo -e ""
	echo -e "For example:"
	echo -e "./$THIS_FILE -t em1"
	exit 0
}

invalid_arg() {
	echo -e "$THIS_FILE: Invalid argument: $1"
	echo -e "Please run with --help for assistance"
	exit 1
}

get_trusted_if_name() {
	echo "$(netstat -ie | grep -B1 "10\." | head -n1 | awk '{print $1}' | cut -d ":" -f1)"
}

verify_trusted_name() {
	given_arg=$1
	current_trusted="$(get_trusted_if_name)"

	if [ $current_trusted == "br0" ]; then
		echo -e "br0 already exists"
		echo -e "please check its configuartion manually"
		exit 0
	fi

	if [ $given_arg != $current_trusted ]; then
		echo -e "Are you sure $given_arg is the trusted name? maybe its $current_trusted?"
		echo -e "Aborting."
		exit 1
	fi
}

create_br0_ifcfg() {
	(
	echo DEVICE=br0
	echo TYPE=Bridge
	echo ONBOOT=yes
	echo BOOTPROTO=dhcp
	echo DELAY=0
	)>$IFCFGS_PATH/ifcfg-br0
}

concat_br0_to_trusted_cfg() {
	echo "BRIDGE=br0" >> ${IFCFGS_PATH}ifcfg-${TRUSTED_IF_NAME}
}


POSITIONAL=()
while [[ $# -gt 0 ]]
do
	key=$1

	case $key in
		-t|--trusted_if_name)
		TRUSTED_IF_NAME="$2"
		shift # past value
		shift
		;;
		-h|--help)
		print_help
		shift # past argument
		;;
		*)    # unknown option
		invalid_arg $1
		POSITIONAL+=("$1") # save it in an array for later
		shift # past argument
		;;
	esac
done

if [ -z $TRUSTED_IF_NAME ]; then
	echo -e "./$THIS_FILE: No argument was given."
	echo -e "Please run with --help for assistance, aborting."
	exit 1
fi

verify_trusted_name $TRUSTED_IF_NAME

create_br0_ifcfg

concat_br0_to_trusted_cfg $TRUSTED_IF_NAME

/etc/init.d/network restart

echo -e "Done"
ifconfig br0
