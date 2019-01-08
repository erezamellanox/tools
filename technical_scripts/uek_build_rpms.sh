#!/bin/bash

THIS_FILE="$(basename "$0")"

if [[ $# -eq 0 ]]
then
	echo -e "No arguments was inserted. for help, please run with the following:"
	echo -e "./$THIS_FILE --help"
fi

NECESSARY_PACKAGES="/.autodirect/mthswgwork/ereza/oracle/rpm_build_packages/*"

print_help() {
	echo -e "Usage:"
	echo -e "./$THIS_FILE -u <uek_path> -r <ref_name> -i <build_id>"
	echo -e ""
	echo -e "For example:"
	echo -e "./$THIS_FILE -u /tmp/linux-uek/ -r HEAD -i orabug_11111"
	exit 0
}

prepare_rpmbuild_dirs() {
        rm -rf ~/rpmbuild/{BUILD,BUILDROOT,RPMS,SOURCES,SPECS,SRPMS}
        mkdir -p ~/rpmbuild/{BUILD,BUILDROOT,RPMS,SOURCES,SPECS,SRPMS}
}

invalid_argument() {
	echo -e "$THIS_FILE: Invalid argument: $1"
	echo -e "Please run with --help for assistance"
	exit 1
}

fix_build_id() { # For example, BUILD_ID="orabug12345" will become BUILD_ID=".orabug12345" as it should be
	first_char="$(echo "${BUILD_ID:0:1}")"
	if [[ $first_char != "." ]]; then
		BUILD_ID=.$BUILD_ID
	fi
}

POSITIONAL=()
while [[ $# -gt 0 ]]
do
	key="$1"

	case $key in
		-u|--uek_path)
		UEK_PATH="$2"
		shift # past argument
		shift # past value
		;;
		-r|--ref)
		REF="$2"
		shift # past argument
		shift # past value
		;;
		-i|--buildid)
		BUILD_ID="$2"
		fix_build_id
		shift # past argument
		shift # past value
		;;
		-h|--help)
		HELP="help requested"
		shift # past argument
		shift # past value
		;;
		*)    # unknown option
		invalid_argument $1
		POSITIONAL+=("$1") # save it in an array for later
		shift # past argument
		;;
	esac
done
set -- "${POSITIONAL[@]}" # restore positional parameters

if [[ ! -z "$HELP" ]]
then
	print_help
	exit 0
fi

echo -e "Installing necessary packages for creating rpm's.."
yum install -y $NECESSARY_PACKAGES 2>&1 >/dev/null

#if [[ $? -ne 0 ]]
#then
#	echo -e "Error installing the necessary packages."
#	echo -e "please try manually:"
#	echo -e "yum install -y $NECESSARY_PACKAGES"
#	echo -e ""
#	exit 1
#fi

echo -e ""

echo -e "Building RPM's with the following parameters:"
echo -e "UEK_PATH=$UEK_PATH , REF=$REF , BUILD_ID=$BUILD_ID"
echo -e ""

if [[ ! -d $UEK_PATH ]]
then
	echo -e "\e[31m Error: $UEK_PATH does not exists\e[0m"
	exit 1
fi

prepare_rpmbuild_dirs
echo -e "Re-created ~/rpmbuild/{BUILD,BUILDROOT,RPMS,SOURCES,SPECS,SRPMS}"
echo -e ""

cd $UEK_PATH

branch="$(git branch | grep \* | cut -d ' ' -f2)"

echo -e "Creating git archive from $branch:$REF.."

rc="$(git archive --format tar --prefix=linux-4.14.35/ $REF | bzip2 > ~/rpmbuild/SOURCES/linux-4.14.35.tar.bz2)"

if [[ $rc -ne 0 ]]
then
	echo -e "\e[31mError creating tar from $REF\e[0m"
	echo -e "\e[31mPlease check again if $REF exists.\e[0m"
	exit 1
fi

echo -e "Done creating archives."
echo -e ""

cp uek-rpm/ol7/* ~/rpmbuild/SOURCES

cd ~/rpmbuild/SOURCES
sed -i "s/# % define buildid .local/%define buildid $BUILD_ID/g" kernel-uek.spec

echo -e ""

echo -e "Starting to create binaries.."
rpmbuild -ba --with baseonly --without debuginfo --target=x86_64 --define "_smp_mflags -j40" kernel-uek.spec 2>&1 | tee compile.log


