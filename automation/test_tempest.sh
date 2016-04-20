#!/bin/bash
x=`find ~ -type f -name "*openrc.sh"`
source $x
cd ~/openstack-ipam/automation/
source ./lib.sh
eval $(heat resource-list gm  | cut -f 2,3 -d\| | tr -d ' ' | grep -v + | tr '|' '=')
FIP=$(neutron floatingip-show -c floating_ip_address -f value $floating_ip)
inst_ip=`heat output-show devstack --all | grep output_value | cut -d':' -f2 | sed s/\",.*$// | sed s/.*\"//`
update_nios_ea_for_tempest $FIP
sshpass -p 'infoblox' scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -r tempest.sh stack@$inst_ip:/home/stack/
sshpass -p 'infoblox' ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no stack@$inst_ip ./tempest.sh

