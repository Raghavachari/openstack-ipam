#!/bin/bash
# Execution Starts
source /home/stack/devstack/openrc admin admin
cd /home/stack/ipam/
rm -rf *.txt
echo "Infoblox Scenario Execution Starts Here"
#./host_and_domain_name_pattern_validation.sh > automation_report.txt 2>&1
python test_clear_cloud_eas.py 2>&1 | tee test_clear_cloud_eas.txt
sleep 60
python test_floating_ip_association.py 2>&1 | test_floating_ip_association.txt
sleep 80
python test_basic_scenario.py 2>&1 | tee test_basic_scenario.txt
sleep 80
python test_host_record.py 2>&1 | test_host_record.txt
sleep 60
python test_interface_attach.py 2>&1 | tee OPENSTACK826.txt
echo "Infoblox Scenario Execution Ends Here"
