#!/bin/sh

if [[ $# -lt 1 ]]
then
	echo "Not Enough Arguments!!"
	exit 1
fi

if [[ $1 -gt 63 || $1 -lt 1 ]]
then
	echo "Invalid Argument!"
	exit 1
fi

modprobe -rv mlx4_en mlx4_ib mlx4_core
modprobe -v mlx4_core num_vfs=$1 probe_vf=$1
modprobe -v mlx4_en && modprobe -v mlx4_ib
