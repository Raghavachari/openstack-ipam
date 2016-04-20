#!/bin/bash
#source ~/./ragha-openrc.sh
x=`find ~ -type f -name "*openrc.sh"`
source $x
cd ~/openstack-ipam/devstack-templates
source ./lib.sh
eval $(heat resource-list gm  | cut -f 2,3 -d\| | tr -d ' ' | grep -v + | tr '|' '=')
FIP=$(neutron floatingip-show -c floating_ip_address -f value $floating_ip)
wait_for_ping $FIP
wait_for_ssl $FIP
sed -i -re 's/(NETWORKING_INFOBLOX_DC_GRID_MASTER_HOST=)[^=]*$/\1'"$FIP"'/' devstack.yaml
heat stack-create -f ~/openstack-ipam/devstack-templates/devstack.yaml -P"fork_name=infobloxopen;branch_name=stable/liberty" devstack
wait_for_stack devstack
inst_ip=`heat output-show devstack --all | grep output_value | cut -d':' -f2 | sed s/\",.*$// | sed s/.*\"//`
wait_for_ping $inst_ip
sleep 150
sshpass -p 'infoblox' scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -r install_devstack.sh stack@$inst_ip:/home/stack/
sshpass -p 'infoblox' ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no stack@$inst_ip ./install_devstack.sh
