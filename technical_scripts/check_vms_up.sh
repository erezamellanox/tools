#!/bin/bash

BASE_IP="10.194"
BASE_IP_NUMS=(9 10)
MACHINE_NUMS=(10 11 12 13 14)
MACHINES_NICS=("CX-3-Pro" "C-IB" "CX-4" "CX-4Lx" "CX-5")
nics_iter=0

for machine in "${MACHINE_NUMS[@]}"
do
	echo -e "\e[4m${MACHINES_NICS[nics_iter]} Machines:\e[0m"
	for base_machine_num in "${BASE_IP_NUMS[@]}"
	do
		nc -z $BASE_IP.$base_machine_num.$machine 22
		if [ $? == 0 ]; then
			echo -e "$BASE_IP.$base_machine_num.$machine is \e[42mOnline\e[0m"
			echo -e "Kernel Version: $(ssh root@$BASE_IP.$base_machine_num.$machine 'uname -r')"
		else
			echo -e "$BASE_IP.$base_machine_num.$machine is \e[41mOffline\e[0m"
		fi
	done
	
	echo -e
	nics_iter=$((nics_iter+1))
done
