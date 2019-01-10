#!/bin/bash
 
DPATH="/sys/kernel/debug/tracing"
PID=$$
OUTPUT="/tmp/mytrace.txt"
THIS_FILE="$(basename "$0")"
COMMAND=""

## Quick basic checks

if [[ $# == 0 ]]; then
	echo -e "No arguments given, please run with --help for further information."
	echo -e "Aborting."
	exit 1
fi

if [[ "$(id -u)" -ne 0 ]]; then
	echo -e "Cannot run ftrace from reqular user."
	echo -e "Please switch to root, Aborting"
	exit 1
fi

mount | grep -i debugfs &> /dev/null

if [[ $? -ne 0 ]]; then
	echo -e "debugfs not mounted, mount it first."
	echo -e "Aborting."
	exit 1
fi

print_help() {
	echo -e "Usage:"
	echo -e "./$THIS_FILE [--options] -c COMMAND"
	echo -e ""
	echo -e "Options:"
	echo -e "-to | --output		Will redirect output to a chosen file"
	echo -e "			By default - /tmp/mytrace.txt"
	echo -e "Examples:"
	echo -e "./$THIS_FILE --output /tmp/myoutput.txt -c ethtool -g ens2f0"
	echo -e "./$THIS_FILE -c ethtool -g ens2f0"
	exit 0
}

invalid_argument() {
	echo -e "$THIS_FILE: Invalid argument: $1"
	echo -e "Please run with --help for assistance"
	exit 1
}

turn_on_tracer() {
	echo nop > $DPATH/current_tracer                # flush existing trace data
	echo function_graph > $DPATH/current_tracer     # set function tracer
	echo 1 > $DPATH/tracing_on                      # enable the current tracer
	echo $PID > $DPATH/set_ftrace_pid               # write current process id to set_ftrace_pid file
	echo 1 > $DPATH/tracing_on                      # start the tracing
}

turn_off_tracer() {
	echo 0 > $DPATH/tracing_on
	echo nop > $DPATH/current_tracer

}

POSITIONAL=()
while [[ $# -gt 0 ]]
do
	key="$1"

	case $key in
		-c|--command)
		shift
		COMMAND="$*"
		break
		;;
		-to|--output)
		OUTPUT=$2
		shift
		shift
		;;
		-h|--help)
		print_help	
		shift
		;;
		*)    				# Unknown option
		invalid_argument $1
		POSITIONAL+=("$1") 		# Save it in an array for later
		shift
		;;
	esac

	if [ ! -z $COMMAND ]; then
		break;
	fi
done
set -- "${POSITIONAL[@]}" 			# restore positional parameters

turn_on_tracer 					# Init ftrace

exec $COMMAND	&				# Execute the process

`cat $DPATH/trace > $OUTPUT`
echo -e "ftrace output has been written to $OUTPUT"

turn_off_tracer					# Shutdown ftrace
