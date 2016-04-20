#!/bin/bash
x=`find ~ -type f -name "*openrc.sh"`
source $x
cd ~/openstack-ipam/grid-templates/
source ./grid-lib.sh
heat stack-create -f ~/openstack-ipam/grid-templates/simple-net.yaml simple-net
wait_for_stack simple-net
heat stack-create -f ~/openstack-ipam/grid-templates/gm.yaml gm
wait_for_stack gm
./config-gm.sh
