#!/bin/bash

function port_first_fixed_ip() {
        neutron port-show -c fixed_ips -f value $1 | sed -e 's/.*ip_address": "\([0-9\.]*\)".*/\1/'
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

function gm_ref() {
	ip=$1
	curl -sk -u admin:infoblox https://$ip/wapi/v2.3/member?host_name=infoblox.localdomain | grep _ref | cut -d: -f2-3 | tr -d '," '
}

function update_nios_ea_for_tempest() {
	grid_ip=$1
        ref=$(gm_ref $grid_ip)
        curl -H "Content-Type: application/json" -sk -u admin:infoblox -X PUT https://$grid_ip/wapi/v2.3/$ref -d '{"extattrs+": {"Default Network View Scope": {"value": "Subnet"},"DHCP Support": {"value": "False"}, "DNS Support": {"value": "False"}, "IP Allocation Strategy":{"value": "Fixed Address"}}}'
	sleep 5
}
