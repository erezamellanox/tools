#!/bin/bash

THIS_FILE="$(basename "$0")"
HOST=""
KERNEL_PATH=""
HELP=""

invalid_arg() {
	echo -e "$THIS_FILE: Invalid argument: $1"
	echo -e "Please run with --help for assistance"
	exit 1
}

print_help() {
	echo -e "Usage:"
	echo -e "./$THIS_FILE -i|--ip HOSTNAME -k|--kernel_rpm_path KERNEL_RPM_PATH"
	echo -e ""
	echo -e "Arguments:"
	echo -e "-i | --ip		-	Host's/guest's ip or hostname"
	echo -e "-k | --kernel_rpm_path	-	Kernel RPM path"
	echo -e ""
	echo -e "For example:"
	echo -e "./$THIS_FILE -i 10.194.13.1 -k /work/x86_64/kernel-4.20.0_mlnx-1.x86_64.rpm"
	echo -e "./$THIS_FILE -i dev-h-vrt-014 -k /work/x86_64/kernel-4.20.0_mlnx-1.x86_64.rpm"
	exit 0
}

POSITIONAL=()
while [[ $# -gt 0 ]]
do
	key=$1

	case $key in
		-i|--ip)
		HOST="$2"
		shift # past value
		shift
		;;
		-k|--kernel_rpm_path)
		KERNEL_PATH="$2"
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

YUM_INSTALL="yum install -y"
GRUB2_MKCONF="grub2-mkconfig -o /boot/grub2/grub.cfg"
GRUB2_S_DEF="grub2-set-default"

echo -e "Checking host availability.."

nc -z $HOST 22 > /dev/null 2>&1

if [[ $? -ne 0 ]]; then
	echo -e "$THIS_FILE: $HOST is unknown or offline"
	exit 1
fi

echo -e "$HOST is online"
echo -e ""

if [ ! -f $KERNEL_PATH ]; then
	echo -e "$THIS_FILE: $KERNEL_PATH: rpm supplied does not exists."
	echo -e "Aborting."
	exit 1
fi

echo -e "Checking grub2 existence.."
grub2_exist=$(ssh $HOST "[[ -e /usr/bin/grub2-file ]]")

if [[ $grub2_exist -ne 0 ]]; then
	echo -e "grub2 does not exist"
	echo -e "installing grub2"
	ssh $HOST "bash ~erez/tools/scripts/install_grub2.sh"
fi

echo -e ""
echo -e "Insalling $(echo $KERNEL_PATH | rev | cut -d "/" -f1 | rev) over $HOST .."

KERNEL_EXIT="$(echo $KERNEL_PATH | rev | cut -d "/" -f 1 | rev | cut -d "-" -f2- | rev | cut -d "." -f2- | rev)"
ssh $HOST "$YUM_INSTALL $KERNEL_PATH" &>/dev/nullEXIT_NUM=$(ssh $HOST "$GRUB2_MKCONF 2>&1 | grep -n "$KERNEL_EXIT" | head -1 | cut -d ":" -f 1")
EXIT_NUM=$(ssh $HOST "$GRUB2_MKCONF 2>&1 | grep -n "$KERNEL_EXIT" | head -1 | cut -d ":" -f 1")
EXIT_NUM=$(($((EXIT_NUM - 1)) / 2))
ssh $HOST "$GRUB2_S_DEF $EXIT_NUM; reboot" &>/dev/null

echo -e "Done installing and rebooted, please check $HOST kernel version in few min"
exit 0
