#!/bin/bash

THIS_FILE="$(basename "$0")"
NEW_DEFAULT_ENTRY=""
GET_ENTRYS_LIST=""
HELP=""
GRUB2_ETC_CFG="/etc/grub2.cfg"

if [[ "$(rpm -q grub2 --quiet)" -ne 0 ]]; then
	echo -e "grub2 is not installed."
	echo -e "Please install grub2, e.g. yum install grub2"
	exit 1
fi

if [[ $# -eq 0 ]]; then
	echo -e "No arguments was inserted. for help, please run with the following:"
	echo -e "./$THIS_FILE --help"
	exit 0
fi

print_help() {
	echo -e "Usage:"
	echo -e "./$THIS_FILE --options"
	echo -e ""
	echo -e "Options:"
	echo -e "-g | --get_entry_list	-	Get entry list, similar to grub2-mkconfig -o /boot/grub2/grub.cfg"
	echo -e "-s | --set_boot_entry	-	Set entry, similar to grub2-set-default <entry>"
	echo -e ""
	echo -e "For example:"
	echo -e "./$THIS_FILE -s 1"
	echo -e "./$THIS_FILE -g"
	exit 0
}

update_grub2() {
	grub2-mkconfig -o /boot/grub2/grub.cfg >/dev/null 2>&1
}

check_valid_entry() {
	chosen_ent=$1
	min_ent=0
	max_ent="$(cat $GRUB2_ETC_CFG | grep "menuentry '" | awk -F[=\'] '{print $2}' | awk '{print NR-1 ". " $0}' | awk 'END{print}' | cut -d "." -f 1)"
	if [ $chosen_ent -lt $min_ent -o $chosen_ent -gt $max_ent ]; then
		echo -e "Invalid entry was chosen: $chosen_ent"
		echo -e ""
		get_entry_list
		exit 1
	fi
}

get_entry_list() {
	cat $GRUB2_ETC_CFG | grep "menuentry '" | awk -F[=\'] '{print $2}' | awk '{print NR-1 ". " $0}'
}

set_default_entry() {
	check_valid_entry $1
	grub2-set-default $1
	ent_chosen="$(get_entry_list | awk "NR==$(($1 + 1))")"
	echo -e "Entry choosed: $ent_chosen"
}

invalid_arg() {
	echo -e "$THIS_FILE: Invalid argument: $1"
	echo -e "Please run with --help for assistance"
	exit 1
}

POSITIONAL=()
while [[ $# -gt 0 ]]
do
	key=$1

	case $key in
		-s|--set_boot_entry)
		NEW_DEFAULT_ENTRY="$2"
		shift # past value
		shift
		;;
		-g|--get_entry_list)
		GET_ENTRYS_LIST="1"
		shift # past value
		;;
		-h|--help)
		HELP="help requested"
		shift # past argument
		;;
		*)    # unknown option
		invalid_arg $1
		POSITIONAL+=("$1") # save it in an array for later
		shift # past argument
		;;
	esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters

if [[ ! -z "$HELP" ]]; then
	print_help
	exit 0
fi

update_grub2

if [[ $GET_ENTRYS_LIST -eq 1 ]]; then
	get_entry_list
	exit 0
fi

if [[ ! -z $NEW_DEFAULT_ENTRY ]]; then
	set_default_entry $NEW_DEFAULT_ENTRY
	exit 0
fi
