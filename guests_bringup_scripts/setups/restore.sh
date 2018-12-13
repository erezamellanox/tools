#!/bin/sh

PASS=$1

#CX3Pro 009-010
sshpass -f <(printf '%s\n' $PASS) rsync ./CX3Pro/9-10/network-scripts/ifcfg-mlx4_* root@10.194.9.10:/etc/sysconfig/network-scripts/
sshpass -f <(printf '%s\n' $PASS) rsync ./CX3Pro/9-10/rdma/*.conf root@10.194.9.10:/etc/rdma
sshpass -f <(printf '%s\n' $PASS) rsync ./CX3Pro/9-10/udev/*.rules root@10.194.9.10:/etc/udev/rules.d/

#CX3Pro 010-010
sshpass -f <(printf '%s\n' $PASS) rsync ./CX3Pro/10-10/network-scripts/ifcfg-mlx4_* root@10.194.10.10:/etc/sysconfig/network-scripts/
sshpass -f <(printf '%s\n' $PASS) rsync ./CX3Pro/10-10/udev/*.rules root@10.194.10.10:/etc/udev/rules.d/

#CIB 009-011
sshpass -f <(printf '%s\n' $PASS) rsync ./CIB/9-11/network-scripts/ifcfg-mlx5_* root@10.194.9.11:/etc/sysconfig/network-scripts/
sshpass -f <(printf '%s\n' $PASS) rsync ./CIB/9-11/rdma/*.conf* root@10.194.9.11:/etc/rdma
sshpass -f <(printf '%s\n' $PASS) rsync ./CIB/9-11/udev/*.rules root@10.194.9.11:/etc/udev/rules.d/

#CIB 010-011
sshpass -f <(printf '%s\n' $PASS) rsync ./CIB/10-11/network-scripts/ifcfg-mlx5_* root@10.194.10.11:/etc/sysconfig/network-scripts/
sshpass -f <(printf '%s\n' $PASS) rsync ./CIB/10-11/udev/*.rules root@10.194.10.11:/etc/udev/rules.d/

#CX4 009-012
sshpass -f <(printf '%s\n' $PASS) rsync ./CX4/9-12/network-scripts/ifcfg-mlx5_* root@10.194.9.12:/etc/sysconfig/network-scripts/
sshpass -f <(printf '%s\n' $PASS) rsync ./CX4/9-12/rdma/*.conf root@10.194.9.12:/etc/rdma
sshpass -f <(printf '%s\n' $PASS) rsync ./CX4/9-12/udev/*.rules root@10.194.9.12:/etc/udev/rules.d/

#CX4 010-012
sshpass -f <(printf '%s\n' $PASS) rsync ./CX4/10-12/network-scripts/ifcfg-mlx5_* root@10.194.10.12:/etc/sysconfig/network-scripts/
sshpass -f <(printf '%s\n' $PASS) rsync ./CX4/10-12/udev/*.rules root@10.194.10.12:/etc/udev/rules.d/

#CX4Lx 009-013
sshpass -f <(printf '%s\n' $PASS) rsync ./CX4Lx/9-13/network-scripts/ifcfg-mlx5_* root@10.194.9.13:/etc/sysconfig/network-scripts/

#CX4Lx 010-013
sshpass -f <(printf '%s\n' $PASS) rsync ./CX4Lx/10-13/network-scripts/ifcfg-mlx5_* root@10.194.10.13:/etc/sysconfig/network-scripts/

#CX5 009-014
sshpass -f <(printf '%s\n' $PASS) rsync ./CX5/9-14/network-scripts/ifcfg-mlx5_* root@10.194.9.14:/etc/sysconfig/network-scripts/
sshpass -f <(printf '%s\n' $PASS) rsync ./CX5/9-14/rdma/*.conf root@10.194.9.14:/etc/rdma
sshpass -f <(printf '%s\n' $PASS) rsync ./CX5/9-14/udev/*.rules root@10.194.9.14:/etc/udev/rules.d/

#CX5 010-014
sshpass -f <(printf '%s\n' $PASS) rsync ./CX5/10-14/network-scripts/ifcfg-mlx5_* root@10.194.10.14:/etc/sysconfig/network-scripts/
sshpass -f <(printf '%s\n' $PASS) rsync ./CX5/10-14/udev/*.rules root@10.194.10.14:/etc/udev/rules.d/

# Enable SM on Boot
./enable_sm.sh
