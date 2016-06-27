#!/bin/bash

## FUNCTIONS FOR GRID CONFIG

function port_first_fixed_ip() {
	neutron port-show -c fixed_ips -f value $1 | sed -e 's/.*ip_address": "\([0-9\.]*\)".*/\1/'
}


function port_gw() {
	subnet_id=$(neutron port-show -c fixed_ips -f value $1 | sed -e 's/.*"subnet_id": "\([-a-z0-9]*\)", .*/\1/')
	neutron subnet-show -c gateway_ip -f value $subnet_id
}

function validate_ha() {
        grid_ip=$1
        member_ha_name=$2

        echo $(date): Checking HA is complete..
        ha_status=$(curl -sk -H "Content-Type: application/json" -u admin:infoblox -X GET https://$grid_ip/wapi/v2.2/member?host_name=$member_ha_name;_return_fields=enable_ha | grep enable_ha | cut -d: -f2-3 | tr -d '," ')
        if [[ "$ha_status" == "true" ]]; then
            echo $(date): HA done successfully..
        fi
}

function wait_for_stack() {
	stack=$1

	echo $(date): Checking if $stack creation is complete...
	st=$(heat stack-show $stack | tr -d ' ' | grep stack_status\| | cut -f3 -d\|)
	while [[ "$st" == *IN_PROGRESS ]]
	do	
		echo $(date): Stack $stack creation not complete yet...waiting...
		sleep 10
		st=$(heat stack-show $stack | tr -d ' ' | grep stack_status\| | cut -f3 -d\|)
	done
	if [[ "$st" == *FAILED ]]; then
		heat stack-show $stack
		exit 1
	fi

	echo $(date): Stack $stack has been created.
}

function wait_for_ping() {
	ip=$1

	echo $(date): Trying to ping $ip...
	ping -c 1 $ip 1>/dev/null 2>&1
	wait=$?
	while [ "$wait" -ne "0" ]
	do
  		echo $(date): Could not ping $ip yet...waiting...
  		sleep 10
		ping -c 1 $ip 1>/dev/null 2>&1
  		wait=$?
	done

	echo
	echo $(date): Ping $ip successful.
	echo
}

function wait_for_ssl() {
	ip=$1

	echo $(date): Trying to create an HTTPS connection to $ip...
	echo | openssl s_client -connect $ip:443 >/dev/null 2>&1
	wait=$?
	while [ "$wait" -ne "0" ]
	do
  		echo $(date): Could not connect to HTTPS...waiting...
  		sleep 10
  		echo | openssl s_client -connect $ip:443 >/dev/null 2>&1
  		wait=$?
	done
	echo $(date): Successfully connected to $ip:443
}

function grid_ref() {
	ip=$1
	curl -sk -u admin:infoblox https://$ip/wapi/v2.3/grid | grep _ref | cut -d: -f2-3 | tr -d '," '
}

function gm_ref() {
	ip=$1
	curl -sk -u admin:infoblox https://$ip/wapi/v2.3/member?host_name=infoblox.localdomain | grep _ref | cut -d: -f2-3 | tr -d '," '
}

function gm_dns_ref() {
	ip=$1
	curl -sk -u admin:infoblox https://$ip/wapi/v2.3/member:dns?host_name=infoblox.localdomain | grep _ref | cut -d: -f2-3 | tr -d '," '
}

function set_permissions() {
        grid_ip=$1

        # Adding "cloud" user to cloud-api-only group
        curl -sk -H "Content-Type: application/json" -u admin:infoblox -X POST https://$grid_ip/wapi/v2.2/adminuser -d '{"admin_groups":["cloud-api-only"],"name": "cloud","password":"cloud"}'

        # Providing all required permissions to cloud-api-only group
        curl -sk -H "Content-Type: application/json" -u admin:infoblox -X POST https://$grid_ip/wapi/v2.2/permission -d '{"group":"cloud-api-only","permission":"WRITE","resource_type":"TENANT"}'
        sleep 3
        curl -sk -H "Content-Type: application/json" -u admin:infoblox -X POST https://$grid_ip/wapi/v2.2/permission -d '{"group":"cloud-api-only","permission":"WRITE","resource_type":"GRID_DHCP_PROPERTIES"}'
        sleep 3
        curl -sk -H "Content-Type: application/json" -u admin:infoblox -X POST https://$grid_ip/wapi/v2.2/permission -d '{"group":"cloud-api-only","permission":"WRITE","resource_type":"NETWORK_VIEW"}'
        sleep 3
        curl -sk -H "Content-Type: application/json" -u admin:infoblox -X POST https://$grid_ip/wapi/v2.2/permission -d '{"group":"cloud-api-only","permission":"WRITE","resource_type":"NETWORK"}'
        sleep 3
        curl -sk -H "Content-Type: application/json" -u admin:infoblox -X POST https://$grid_ip/wapi/v2.2/permission -d '{"group":"cloud-api-only","permission":"WRITE","resource_type":"IPV6_NETWORK"}'
        sleep 3
        curl -sk -H "Content-Type: application/json" -u admin:infoblox -X POST https://$grid_ip/wapi/v2.2/permission -d '{"group":"cloud-api-only","permission":"WRITE","resource_type":"HOST"}'
        sleep 3
        curl -sk -H "Content-Type: application/json" -u admin:infoblox -X POST https://$grid_ip/wapi/v2.2/permission -d '{"group":"cloud-api-only","permission":"WRITE","resource_type":"GRID_DNS_PROPERTIES"}'
        sleep 3
        curl -sk -H "Content-Type: application/json" -u admin:infoblox -X POST https://$grid_ip/wapi/v2.2/permission -d '{"group":"cloud-api-only","permission":"WRITE","resource_type":"VIEW"}'
        sleep 3
        curl -sk -H "Content-Type: application/json" -u admin:infoblox -X POST https://$grid_ip/wapi/v2.2/permission -d '{"group":"cloud-api-only","permission":"WRITE","resource_type":"ZONE"}'
        sleep 3
        curl -sk -H "Content-Type: application/json" -u admin:infoblox -X POST https://$grid_ip/wapi/v2.2/permission -d '{"group":"cloud-api-only","permission":"WRITE","resource_type":"MEMBER"}'
        sleep 3
        curl -sk -H "Content-Type: application/json" -u admin:infoblox -X POST https://$grid_ip/wapi/v2.2/permission -d '{"group":"cloud-api-only","permission":"WRITE","resource_type":"NETWORK_DISCOVERY"}'
        sleep 3
        curl -sk -H "Content-Type: application/json" -u admin:infoblox -X POST https://$grid_ip/wapi/v2.2/permission -d '{"group":"cloud-api-only","permission":"WRITE","resource_type":"SCHEDULE_TASK"}'
        sleep 3
        curl -sk -H "Content-Type: application/json" -u admin:infoblox -X POST https://$grid_ip/wapi/v2.2/permission -d '{"group":"cloud-api-only","permission":"WRITE","resource_type":"A"}'
        sleep 3
        curl -sk -H "Content-Type: application/json" -u admin:infoblox -X POST https://$grid_ip/wapi/v2.2/permission -d '{"group":"cloud-api-only","permission":"WRITE","resource_type":"PTR"}'
        sleep 3
}

function wait_for_wapi() {
	ip=$1
	ref=""
	while [[ -z "$ref" ]]; do
		echo $(date): Waiting for WAPI...
		ref=$(grid_ref $ip)
	done

	echo 
	echo $(date): Done - grid $ref
	echo
}

function download_cert() {
	ip=$1
	file=$2
	echo $(date): Downloading certificate from $ip for use in member join...
	echo
	echo | openssl s_client -connect $ip:443 2>/dev/null | openssl x509 | sed -e 's/^/    /' > $file
	echo $(date): Done
}


function grid_set_ha() {
	fip=$1
	ref=$2
	vip=$3
	gw=$4
	n1lan=$5
	n1ha=$6
	n2lan=$7
	n2ha=$8
	echo "On $fip, setting $ref networking to (vip=$vip, gw=$gw, n1lan=$n1lan, n1ha=$n1ha, n2lan=$n2lan, n2ha=$n2ha)..."
	echo $(curl -sk -u admin:infoblox -X PUT -H 'Content-Type: application/json' -d "{\"enable_ha\": true, \"router_id\": 200, \"vip_setting\": {\"address\": \"$vip\", \"gateway\": \"$gw\", \"subnet_mask\": \"255.255.255.0\" }, \"node_info\": [{\"lan_ha_port_setting\": { \"ha_ip_address\": \"$n1ha\", \"mgmt_lan\": \"$n1lan\"}}, {\"lan_ha_port_setting\": {\"ha_ip_address\": \"$n2ha\", \"mgmt_lan\": \"$n2lan\"}}]}" https://$fip/wapi/v2.3/$ref)
	echo
}

function grid_join() {
	vip=$1
	fip=$2
	
	echo "Joining $fip to grid at $vip..."
	ref=$(grid_ref $fip)
	echo $(curl -sk -u admin:infoblox -X POST "https://$fip/wapi/v2.3/$ref?_function=join&master=$vip&shared_secret=test&grid_name=Infoblox")
	echo
}

function grid_snmp() {
	fip=$1
	echo "Enabling SNMP..."
	echo $(curl -sk -u admin:infoblox -X PUT -H "Content-Type: application/json" -d '{"snmp_setting": {"queries_enable": true, "queries_community_string": "public"}}' https://$fip/wapi/v2.3/$(grid_ref $fip))
}


function grid_dns() {
	fip=$1
	echo "Enabling DNS..."
	echo $(curl -sk -u admin:infoblox -X PUT -H "Content-Type: application/json" -d '{"enable_dns": true}' https://$fip/wapi/v2.3/$(gm_dns_ref $fip))
}

function grid_nsgroup() {
	fip=$1
	echo "Adding a default nsgroup..."
	echo $(curl -sk -u admin:infoblox -X POST -H "Content-Type: application/json" -d '{"name": "default", "is_grid_default": true, "grid_primary": [{"name": "infoblox.localdomain"}]}' https://$fip/wapi/v2.3/nsgroup)
}

function write_env() {
	fip=$1
	vip=$2
	fip_id=$3

	cert_file=/tmp/gm-$fip-cert.pem
	env_file=gm-$fip-env.yaml

	download_cert $fip $cert_file

	FIP_NET_ID=$(neutron floatingip-show -c floating_network_id -f value $fip_id)
	FIP_NET=$(neutron net-show -c name -f value $FIP_NET_ID)

	cat > $env_file <<EOF
# Heat environment for launching autoscale against GM $fip
parameters:
  gm_vip: $vip
  external_network: $FIP_NET
  gm_cert: |
EOF

	cat >> $env_file < $cert_file

	cat >> $env_file <<EOF
parameter_defaults:
  wapi_url: https://$fip/wapi/v2.3/
  wapi_username: admin
  wapi_password: infoblox
  wapi_sslverify: false
EOF
}

