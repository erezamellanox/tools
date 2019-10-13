#!/bin/bash

THIS_FILE="$(basename "$0")"
EXPORTS_FILE="/etc/exports"
EXPORT_PROP="*(rw,sync,no_root_squash,no_all_squash)"

check_path_exists() {
	if ssh $1 '[ -d $2 ]'; then
        	echo -e "$1:$2 - path exists"
		return
	fi
	echo -e "$1:$2 - Path not exists."
	exit 1
}

check_machine_exists() {
	nc -z $1 22 > /dev/null 2>&1

	if [[ $? -ne 0 ]]; then
        	echo -e "$THIS_FILE: $1 is unknown or offline"
        	exit 1
	fi
}

print_help() {
	echo -e "Usage:"
	echo -e "./$THIS_FILE [--options] -c COMMAND"
	echo -e ""
	echo -e "Arguments:"
	echo -e "-dm | --dest_machine		Destination machine to mount directory"
	echo -e "-dm | --dest_machine           Source machine to mount directory"
	echo -e "-dp | --dst_path		Destination machine path to put the mounted dir"
	echo -e "-sp | --src_path               Source machine path to wanted directory"
	echo -e "Examples:"
	echo -e "./$THIS_FILE -sm qa-h-vrt-085 -sp /tmp/linux-uek/ -dm qa-h-vrt-085 -dp /usr/linux-uek/"
	exit 0
}

invalid_argument() {
	echo -e "$THIS_FILE: Invalid argument: $1"
	echo -e "Please run with --help for assistance"
	exit 1
}

if [[ $# != 8 ]]; then
	echo -e "Invalid number of arguments given: $#, please run with --help for further information."
	echo -e "Aborting."
	exit 1
fi


POSITIONAL=()
while [[ $# -gt 0 ]]
do
	key="$1"

	case $key in
		-dm|--dest_machine)
		DEST_MACHINE=$2
		shift
		shift
		;;
		-sm|--src_machine)
		SRC_MACHINE=$2
		shift
		shift
		;;
		-dp|--dst_path)
                DEST_PATH=$2
                shift
                shift
                ;;
		-sp|--src_path)
		SRC_PATH=$2
		shift
		shift
		;;
		-h|--help)
		echo "im here calling for help"
                print_help
                ;;
		*)    				# Unknown option
		invalid_argument $1
		POSITIONAL+=("$1") 		# Save it in an array for later
		shift
		;;
	esac
done
set -- "${POSITIONAL[@]}" 			# restore positional parameters


echo -e "Requested to mount $SRC_MACHINE:$SRC_PATH into $DEST_MACHINE:$DEST_PATH\n"

echo -e "Checking source machine.."
check_machine_exists $SRC_MACHINE
echo -e "$SRC_MACHINE is online\n"

echo -e "Checking destination machine.."
check_machine_exists $DEST_MACHINE
echo -e "$DEST_MACHINE is online\n"

echo -e "Checking path exists in source machine.."
check_path_exists $SRC_MACHINE $SRC_PATH
echo -e ""

echo -e "Checking path exists in destination machine.."
check_path_exists $DEST_MACHINE $DEST_PATH
echo -e ""

# Configure mounting
command_src="$SRC_PATH *(rw,sync,no_root_squash,no_all_squash)"
ssh $SRC_MACHINE 'echo $command_src > $EXPORTS_FILE'
ssh $SRC_MACHINE 'service nfs restart'

# Mount
ssh $DEST_MACHINE 'mount $SRC_MACHINE:$SRC_PATH $DEST_PATH'
