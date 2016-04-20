#!/bin/bash
#source ~/./ragha-openrc.sh
x=`find ~ -type f -name "*openrc.sh"`
source $x
cd ~/openstack-ipam/automation
source ./lib.sh
eval $(heat resource-list gm  | cut -f 2,3 -d\| | tr -d ' ' | grep -v + | tr '|' '=')
FIP=$(neutron floatingip-show -c floating_ip_address -f value $floating_ip)
#LAN=$(port_first_fixed_ip $lan1_port)
wait_for_ping $FIP
wait_for_ssl $FIP
sed -i -re 's/(GRID_VIP =)[^=]*$/\1'" $FIP"'/' ~/openstack-ipam/automation/ipam/config.ini
inst_ip=`heat output-show devstack --all | grep output_value | cut -d':' -f2 | sed s/\",.*$// | sed s/.*\"//`
sshpass -p 'infoblox' scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -r ~/openstack-ipam/automation/ipam/ stack@$inst_ip:/home/stack/
sshpass -p 'infoblox' scp -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no -r ~/openstack-ipam/automation/execution.sh stack@$inst_ip:/home/stack/
sshpass -p 'infoblox' ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no stack@$inst_ip ./execution.sh
