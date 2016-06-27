#!/bin/bash
#source /opt/devstack/openrc
if [[ -z "$OS_USERNAME" ]]; then
        echo "You must set up your OpenStack environment (source an openrc.sh file)."
        exit 1
fi

cd ~/openstack-ipam/grid-templates/
source ./grid-lib.sh

# Creating networks for environment
heat stack-create -f ~/openstack-ipam/grid-templates/simple-net.yaml simple-net
wait_for_stack simple-net
heat stack-create -f ~/openstack-ipam/grid-templates/gm.yaml gm
wait_for_stack gm
./config-gm.sh
eval $(heat resource-list gm  | cut -f 2,3 -d\| | tr -d ' ' | grep -v + | tr '|' '=')

# Get the GM FIP information
FIP=$(neutron floatingip-show -c floating_ip_address -f value $floating_ip)
wait_for_ping $FIP
wait_for_ssl $FIP

# Get GM certificate
gm_cert=$(echo | openssl s_client -connect $FIP:443 2>/dev/null | openssl x509)
heat stack-create -f ~/openstack-ipam/grid-templates/member-ha.yaml -P "gm_cert=$gm_cert;gm_vip=$FIP;lan1_network=protocol-net;security_group=Infoblox;wapi_password=infoblox;wapi_url=https://$FIP/wapi/v2.3/;wapi_username=admin" member-ha
wait_for_stack member-ha
vip_floating_ip=`heat resource-list member-ha | cut -f 2,3 -d\| | tr -d ' ' | grep -v + | grep vip_floating_ip | cut -f 2 -d '|'`
Member_FIP=$(neutron floatingip-show -c floating_ip_address -f value $vip_floating_ip)
wait_for_ping $Member_FIP
wait_for_ssl $Member_FIP
member_ha_name=$(heat resource-list member-ha | cut -f 2,3 -d\| | tr -d ' ' | grep -v + | tr '|' '=' | grep grid_member= | sed 's/............//')
validate_ha $FIP $member_ha_name
