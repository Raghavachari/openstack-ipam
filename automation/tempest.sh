#!/bin/bash
cd
cd devstack
source openrc admin admin
ext_net_id=`neutron net-create ext-net --router:external True -f value -c id | tail -1`
echo $ext_net_id
ext_snet_id=`neutron subnet-create ext-net 10.222.245.0/24 -f value -c id | tail -1`
echo $ext_snet_id
sed -i "s/^\(public_network_id\s*=\s*\).*$/\1$ext_net_id/" /opt/stack/tempest/etc/tempest.conf

sudo apt-get install python-pip python-dev build-essential libffi6 libffi-dev libssl-dev -y
sudo pip install virtualenv
cd /opt/stack/tempest/
sudo pip install -r test-requirements.txt
#./run_tempest.sh -V tempest.api.network.test_networks
./run_tempest.sh -V tempest.api.network.test_ports 2>&1 | tee tempest_api_network_test_ports
neutron net-delete $ext_net_id
mkdir -p /home/stack/reports
cp -r /opt/stack/tempest/tempest_api* /home/stack/reports/
sleep 30
