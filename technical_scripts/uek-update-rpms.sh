#!/bin/bash

UEK_TREE_PATH="/tmp/linux-uek/"
UEK_RESPECTIVE_BRANCH="origin/uek5/master"
UEK_LATEST_RPM_DIR="/.autodirect/mthswgwork/ereza/oracle/kernel-rpms/latest/"
UEK_INTERNAL_RPM_DIR="/.autodirect/mthswgwork/ereza/oracle/kernel-rpms/"
ORACLE_YUM_LATEST_REPO="https://yum.oracle.com/repo/OracleLinux/OL7/developer_UEKR5/x86_64"
MELLANOX_DIRS="drivers/net/ethernet/mellanox/ drivers/infiniband/hw/mlx4/ drivers/infiniband/hw/mlx5/ drivers/infiniband/core/"

git_update_tree() {
	cd $UEK_TREE_PATH
	git_checkout_master > /dev/null 2>&1
	git branch | grep -ve " master$" | xargs git branch -D
	git remote update
	git pull 
}

get_mellanox_changes() {
	from=$1
	to=$2
	local_b="_local"
	cd $UEK_TREE_PATH
	git checkout -b v$to$local_b v$to > /dev/null 2>&1
	git log --pretty=format:'%h By %an, %ar, %s %n' v$from..v$to $MELLANOX_DIRS
	git_checkout_master > /dev/null 2>&1
	git b -D v$to$local_b > /dev/null 2>&1
}

check_rpm_availability() {
	packages_types=$1
	tag=$2
	get_package=$3
	arch=$4
	for package in "${packages_types[@]}"
	do
		status=$(curl -s --head -w %{http_code} $ORACLE_YUM_LATEST_REPO$get_package$package-$tag$arch -o /dev/null)
		if [[ $status -ne 0 ]]
		then
			echo $status
			return
		fi
	done

	return 0
}
	
download_latest_rpms() {
	tag=$1
	lastest="latest/"
	local arch=".el7uek.x86_64.rpm"
	get_package="/getPackage/"
	packages_types=("kernel-uek" "kernel-uek-debug-devel" "kernel-uek-devel" "kernel-uek-tools")
	ret=$(check_rpm_availability $packages_types $tag $get_package $arch)

	if [[ $ret -ne 0 ]]
	then
		echo -e "RPM's are not available is the repo currently"
		echo -e ""
		return 0
	fi

	cd $UEK_INTERNAL_RPM_DIR
        mkdir $latest_mthswgwork
        mv $lastest* $latest_mthswgwork
        cd $lastest
	for package in "${packages_types[@]}"
	do		
		#echo -e "Downloading $package-$tag"
		wget $ORACLE_YUM_LATEST_REPO$get_package$package-$tag$arch > /dev/null 2>&1
		if [ $? -ne 0 ]
		then
			echo -e "Failed downloading rpm: $package-$tag"
			exit 1
		fi
		#echo -e "$package-$tag was downloaded"
		
	done
	echo -e "The RPM's for this version ({kernel, debug-devel, devel, tools} - $tag) has been downloaded to:"
	echo -e "$UEK_INTERNAL_RPM_DIR$lastest"
	echo -e ""
}

check_latest_rpm_mthswgwork() {
	latest_tag_from_oracle=$1
	cd $UEK_LATEST_RPM_DIR
	latest_in_dir=$(ls -al $UEK_LATEST_RPM_DIR | awk '{print $NF}' | grep kernel-uek-4 | cut -c 12- | awk -F '.el7' '{print $1}')
	echo $latest_in_dir
}

git_checkout_master() {
	git reset --hard
	git clean -fd
	git checkout master
}

check_latest_tag() {
        cd $UEK_TREE_PATH
        local_br="_local"
        git checkout -b $UEK_RESPECTIVE_BRANCH$local_br $UEK_RESPECTIVE_BRANCH >/dev/null 2>&1
        local latest=$(git describe --abbrev=0 --tags | cut -c 2-)
	git_checkout_master > /dev/null 2>&1
        git b -D $UEK_RESPECTIVE_BRANCH$local_br > /dev/null 2>&1
	echo $latest
}

git_update_tree > /dev/null 2>&1

latest_tag=$(check_latest_tag)

latest_mthswgwork="$(check_latest_rpm_mthswgwork)"

if [ "$latest_tag" == "$latest_mthswgwork" ]
then
	echo -e "No new tag for UEK-5"
	exit 1
else
	echo -e "New UEK-5 tag is now available: $latest_tag"
	echo -e ""
	#echo -e "Downloading RPM's.."
	download_latest_rpms $latest_tag
	changes=$(get_mellanox_changes $latest_mthswgwork $latest_tag)
	if [ -z "$changes" ]
	then
		echo -e "No change related to Mellanox in this version."
		exit 0
	else
		echo -e "Relevant Log:"
		echo "$changes"
		printf "\n\n\n"
		echo "(This is an automated script, please do not respond to this mail)"
	fi
fi

exit 0
