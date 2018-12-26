# This script run basic sanity tests between qa-h-vrt-085/086

THIS_FILE="$(basename "$0")"
ROOT_PASSWORD=""
SANITY_SCRIPTS_DIR=""

invalid_arg() {
	echo -e "$THIS_FILE: Invalid argument: $1"
	echo -e "Please run with --help for assistance"
	exit 1
}

print_help() {
	echo -e "Usage:"
	echo -e "./$THIS_FILE -r|--root_password ROOT_PASS -p|--sanity_scripts_path SANITY_SCRIPTS_DIR"
	echo -e ""
	echo -e "Arguments:"
	echo -e "-r | --root_password		-	Root password"
	echo -e "-p | --sanity_scripts_path	-	Python based sanity scripts directory"
	echo -e ""
	echo -e "For example:"
	echo -e "./$THIS_FILE -r 123456 -p /work/sanity/"
	exit 0
}

if [ $# -lt 4 ]
then
	echo -e "Not enough arguments."
	echo -e "Please run with --help for information."
	exit 1
fi

POSITIONAL=()
while [[ $# -gt 0 ]]
do
	key=$1

	case $key in
		-r|--root_password)
		ROOT_PASSWORD="$2"
		shift # past value
		shift
		;;
		-p|--sanity_scripts_path)
		SANITY_SCRIPTS_DIR="$2"
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

if [ ! -f /usr/bin/sshpass ]
then
	echo -e "Please install sshpass, e.g."
	echo -e "yum install -y sshpass"
	echo -e "OR"
	echo -e "yum install -y https://rpmfind.net/linux/epel/7/x86_64/Packages/s/sshpass-1.06-1.el7.x86_64.rpm"
	exit 1
fi

declare -a SUFFIXES=("085" "086")
echo -e "\e[104mInstalling Ver-Tools over both machines...\e[0m\n"
for suffix in "${SUFFIXES[@]}" 
do
	sshpass -p $ROOT_PASSWORD ssh root@qa-h-vrt-$suffix << 'ENDSSH'
		if [ ! -f /usr/bin/mlx_traffic_test ]; then
			/.autodirect/mswg/projects/ver_tools/reg2_last_stable/install.sh
		else
			echo -e "\e[104m$suffix - Vertools already installed\e[0m\n"
		fi
ENDSSH
done

echo -e "\e[32mVertools stage - Done!\e[0m\n"
echo -e "\e[104mRaising OpenSM over qa-h-vrt-085..\e[0m"

sshpass -p $ROOT_PASSWORD ssh root@qa-h-vrt-085 << 'ENDSSH'
	GUID_PORT_1="$(ibstat mlx4_0 | grep "Port GUID" | cut -d " " -f 3 | head -1)"
	GUID_PORT_2="$(ibstat mlx4_0 | grep "Port GUID" | cut -d " " -f 3 | tail -1)"
	opensm -g ${GUID_PORT_1} &> /dev/null &
	echo -e "opensm -g ${GUID_PORT_1}"
	opensm -g ${GUID_PORT_2} &> /dev/null &
	echo -e "opensm -g ${GUID_PORT_2}"
	# echo "First GUID is ${GUID_PORT_1}"
	# echo "Sencond GUID is ${GUID_PORT_2}"
ENDSSH

echo -e "\e[104mOpenSM - Done!\e[0m\n"

# Defining IP's for the Interfaces on both servers (085-086)
for suffix in "${SUFFIXES[@]}"
do
	echo -e "\e[104mSetting IP's for $suffix interfaces\e[0m"
	sshpass -p $ROOT_PASSWORD ssh root@qa-h-vrt-$suffix << 'ENDSSH'
		HOSTNAME=$(hostname | cut -d "0" -f 2)
		declare -a IPS_NUM=("85" "86")
		declare -a VLANS_ID=("70" "80")
		id=0
		if [ "$HOSTNAME" == "${IPS_NUM[O]}" ]
		then
			j=0
		else
			j=1
		fi
		declare -a IPS=("11.194.${IPS_NUM[j]}.1/16" "12.194.${IPS_NUM[j]}.1/16" "13.194.${IPS_NUM[j]}.1/16" "14.194.${IPS_NUM[j]}.1/16")
		i=0
		PCI_LIST=( $(lspci | grep nox | cut -d " " -f 1) );
		for pci_id in "${PCI_LIST[@]}"
		do
			if="$(ls -al /sys/class/net | grep $pci_id | awk -F "/net/" '{print $2}')"
			if (( $(grep -c . <<<"$if") > 1 )); then
  				while read -r line; do
					# echo -e "The Following command is going to be executed: ifconfig $line ${IPS_85[i]}"
					ifconfig $line ${IPS[i]}
					echo -e "$line ---> ${IPS[i]}";
					i=$((i+1))
				done <<< "$if"
			else
				# echo -e "The Following command is going to be executed: ifconfig $if ${IPS[i]}"
				ifconfig $if ${IPS[i]}
				echo -e "$if ---> ${IPS[i]}";
				vlan_id=${VLANS_ID[id]}
				ip link add link $if name $if.$vlan_id type vlan id $vlan_id
				ifconfig $if.$vlan_id $(echo ${IPS[i]} | sed s/1/2/1)
				echo "vlan configured: $if.$vlan_id --> $(echo ${IPS[i]} | sed s/1/2/1)"
				id=$((id+1))
				i=$((i+1))
			fi
		done
ENDSSH
echo -e ""
done

echo -e "\e[104m===================================================Begginnig Sanity===================================================\e[0m\n"

cd $SANITY_SCRIPTS_DIR

echo -e "\e[104mIP (CX-5 Ethernet)\e[0m"
./ip_traffic.py -s qa-h-vrt-086 -c qa-h-vrt-085 -n 11.194.0.0
./ip_traffic.py -s qa-h-vrt-086 -c qa-h-vrt-085 -n 12.194.0.0

echo -e "\e[104mIP over VLANs (CX-5 Ethernet)\e[0m"
./ip_traffic.py -s qa-h-vrt-086 -c qa-h-vrt-085 -n 21.194.0.0
./ip_traffic.py -s qa-h-vrt-086 -c qa-h-vrt-085 -n 22.194.0.0

echo -e "\e[104mIP (CX-3 IPoIB)\e[0m"
./ip_traffic.py -s qa-h-vrt-086 -c qa-h-vrt-085 -n 13.194.0.0
./ip_traffic.py -s qa-h-vrt-086 -c qa-h-vrt-085 -n 14.194.0.0

echo -e "\e[104mRDMA (ConnectX-3 IB)\e[0m"
./rdma_traffic.py -d mlx4_0 -i 0 -s qa-h-vrt-085 -c qa-h-vrt-086 -p 1

echo -e "\e[104mRDMA (ConnectX-5 RoCE)\e[0m"
for physical_port in {1..2}
do
	for gid_index in {0..3}
	do
		./rdma_traffic.py -d mlx5_0 -i $gid_index -s qa-h-vrt-085 -c qa-h-vrt-086 -p $physical_port
	done
done

echo -e "\e[104mRDMA over VLANs (ConnectX-5 RoCE)\e[0m"
for physical_port in {1..2}
do
        for gid_index in {4..5}
        do
        ./rdma_traffic.py -d mlx5_0 -i $gid_index -s 21.194.85.1 -c 21.194.86.1 -p $physical_port
        ./rdma_traffic.py -d mlx5_0 -i $gid_index -s 22.194.85.1 -c 22.194.86.1 -p $physical_port
        done
done

echo -e "\e[104mRDMACM (ConnectX-3 IB)\e[0m"
./rdmacm_traffic.py -s 10.195.85.1 -c 10.195.86.1 --tested_server 13.194.85.1 --tested_client 13.194.86.1
./rdmacm_traffic.py -s 10.195.85.1 -c 10.195.86.1 --tested_server 14.194.85.1 --tested_client 14.194.86.1

echo -e "\e[104mRDMACM (ConnectX-5 RoCE)\e[0m\n"
./rdmacm_traffic.py -s 10.195.85.1 -c 10.195.86.1 --tested_server 11.194.85.1 --tested_client 11.194.86.1
./rdmacm_traffic.py -s 10.195.85.1 -c 10.195.86.1 --tested_server 12.194.85.1 --tested_client 12.194.86.1

echo -e "\e[104mRDMACM over VLANS (ConnectX-5 RoCE)\e[0m\n"
./rdmacm_traffic.py -s 10.195.85.1 -c 10.195.86.1 --tested_server 21.194.85.1 --tested_client 21.194.86.1
./rdmacm_traffic.py -s 10.195.85.1 -c 10.195.86.1 --tested_server 22.194.85.1 --tested_client 22.194.86.1

echo -e "Restart driver tests.."
ssh 10.195.85.1 "bash ~ereza/tools/scripts/reload_mlx5.sh"
ssh 10.195.85.1 "bash ~ereza/tools/scripts/reload_mlx4.sh"
ssh 10.195.86.1 "bash ~ereza/tools/scripts/reload_mlx5.sh"
ssh 10.195.86.1 "bash ~ereza/tools/scripts/reload_mlx4.sh"
