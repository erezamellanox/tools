#!/bin/bash
# Erez Alfasi, March 2018.
# This script run sanity testing between my machines 009-010
# CX3-Pro - 009-010 <-----------> 010-010
# CX5     - 009-014 <-----------> 010-014

cd /.autodirect/mthswgwork/kamalh/scripts/sanity

# Ethernet (Including vlans):
./ip_traffic.py -s dev-h-vrt-009-010 -c dev-h-vrt-010-010 -n 12.194.0.0		
./ip_traffic.py -s dev-h-vrt-009-010 -c dev-h-vrt-010-010 -n 43.194.0.0		# vlan43
./ip_traffic.py -s dev-h-vrt-009-010 -c dev-h-vrt-010-010 -n 45.194.0.0		# vlan45

./ip_traffic.py -s dev-h-vrt-009-014 -c dev-h-vrt-010-014 -n 12.194.0.0
./ip_traffic.py -s dev-h-vrt-009-014 -c dev-h-vrt-010-014 -n 43.194.0.0		# vlan43
./ip_traffic.py -s dev-h-vrt-009-014 -c dev-h-vrt-010-014 -n 45.194.0.0		# vlan45

# IPoIB (Including P_Keys):
./ip_traffic.py -s dev-h-vrt-009-010 -c dev-h-vrt-010-010 -n 11.194.0.0		
./ip_traffic.py -s dev-h-vrt-009-010 -c dev-h-vrt-010-010 -n 52.194.0.0		# P_key52
./ip_traffic.py -s dev-h-vrt-009-010 -c dev-h-vrt-010-010 -n 53.194.0.0		# P_key53

./ip_traffic.py -s dev-h-vrt-009-014 -c dev-h-vrt-010-014 -n 11.194.0.0
./ip_traffic.py -s dev-h-vrt-009-014 -c dev-h-vrt-010-014 -n 52.194.0.0		# P_key52
./ip_traffic.py -s dev-h-vrt-009-014 -c dev-h-vrt-010-014 -n 53.194.0.0		# P_key53

# RDMA:
./rdma_traffic.py -d mlx4_0 -i 0 -s dev-h-vrt-009-010 -c dev-h-vrt-010-010 -p 1		# Infiniband
./rdma_traffic.py -d mlx4_0 -i 0 -s dev-h-vrt-009-010 -c dev-h-vrt-010-010 -p 2		# RoCE v1 (CX-3 Doesnt support RoCE v2)
./rdma_traffic.py -d mlx4_0 -i 6 -s dev-h-vrt-009-010 -c dev-h-vrt-010-010 -p 2		# RoCE v1 (vlan43)
./rdma_traffic.py -d mlx4_0 -i 10 -s dev-h-vrt-009-010 -c dev-h-vrt-010-010 -p 2	# RoCE v1 (vlan45)

./rdma_traffic.py -d mlx5_0 -i 0 -s dev-h-vrt-009-014 -c dev-h-vrt-010-014 -p 1		# Infiniband
./rdma_traffic.py -d mlx5_1 -i 0 -s dev-h-vrt-009-014 -c dev-h-vrt-010-014 -p 1		# RoCE v1
./rdma_traffic.py -d mlx5_1 -i 1 -s dev-h-vrt-009-014 -c dev-h-vrt-010-014 -p 1		# RoCE v2
./rdma_traffic.py -d mlx5_1 -i 6 -s dev-h-vrt-009-014 -c dev-h-vrt-010-014 -p 1		# RoCE v1 (vlan43)
./rdma_traffic.py -d mlx5_1 -i 7 -s dev-h-vrt-009-014 -c dev-h-vrt-010-014 -p 1		# RoCE v2 (vlan43)
./rdma_traffic.py -d mlx5_1 -i 10 -s dev-h-vrt-009-014 -c dev-h-vrt-010-014 -p 1	# RoCE v1 (vlan45)
./rdma_traffic.py -d mlx5_1 -i 11 -s dev-h-vrt-009-014 -c dev-h-vrt-010-014 -p 1	# RoCE v2 (vlan45)

# RDMACM:
./rdmacm_traffic.py -s 10.194.9.10 -c 10.194.10.10 --tested_server 11.194.9.10 --tested_client 11.194.10.10
./rdmacm_traffic.py -s 10.194.9.10 -c 10.194.10.10 --tested_server 52.194.9.10 --tested_client 52.194.10.10	# P_key52
./rdmacm_traffic.py -s 10.194.9.10 -c 10.194.10.10 --tested_server 53.194.9.10 --tested_client 53.194.10.10	# P_key53

./rdmacm_traffic.py -s 10.194.9.14 -c 10.194.10.14 --tested_server 11.194.9.14 --tested_client 11.194.10.14
./rdmacm_traffic.py -s 10.194.9.14 -c 10.194.10.14 --tested_server 52.194.9.14 --tested_client 52.194.10.14     # P_key52
./rdmacm_traffic.py -s 10.194.9.14 -c 10.194.10.14 --tested_server 53.194.9.14 --tested_client 53.194.10.14     # P_key53

