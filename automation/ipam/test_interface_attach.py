from util import *
from json import loads
from json import dumps
import unittest
import ConfigParser
import time

tenant_name = "admin"
network = "net"
subnet_name = "snet"
subnet = "129.127.0.0/24"
instance = "host"
CONF = "config.ini"
parser = ConfigParser.SafeConfigParser()
parser.read(CONF)
gm_ip = parser.get('Default', 'GRID_VIP')


class TestInterfaceAttach(unittest.TestCase):
    def test_instance_A_record(self):
        args = "name=%s" % (host_name)
        code, msg = wapi_get_request("record:a", args)
        if code == 200 and len(loads(msg)) > 0:
            self.assertEqual(loads(msg)[0]['name'], host_name)
        else:
            self.fail("Record Mismatch %s" % host_name)

    def test_instance_new_interface_record(self):
        args = "ipv4addr=%s" % (ips['net'][1]['addr'])
        code, msg = wapi_get_request("record:a", args)
        if code == 200 and len(loads(msg)) > 0:
            self.assertEqual(loads(msg)[0]['name'], host_name2)
        else:
            self.fail("Record Mismatch %s" % host_name2)

s = utils(tenant_name)
params="?host_name=infoblox.localdomain" 
gm_ref = wapi_request('GET', object_type="member", params=params)
ref = loads(gm_ref)[0]['_ref']
data = {"extattrs+": {"Default Host Name Pattern": {"value": "host-{instance_name}"}, "Default Network View Scope": {"value": "Single"}, "Default Network View": {"value": "default"}, "Admin Network Deletion": {"value": "True"}, "DHCP Support": {"value": "True"}, "DNS Support": {"value": "True"}, "IP Allocation Strategy": {"value": "Fixed Address"}, "Default Domain Name Pattern": {"value": "{subnet_id}.cloud.global.com"}}}
wapi_request('PUT', object_type=ref,fields=dumps(data))
time.sleep(20)

s.create_network(network)
s.create_subnet(network, subnet_name, subnet)
s1 = s.launch_instance(instance, network)
iface = s.interface_attach(s1.id,network)
ips = s.get_instance_ips(instance)
host_name = s.get_hostname_pattern_from_grid_config(ips['net'][0]['addr'],s1,network,subnet_name)
host_name2 = s.get_hostname_pattern_from_grid_config(ips['net'][1]['addr'],s1,network,subnet_name)
port_id = s.get_instance_port_id(s1.networks['net'][0])
fqdn = s.get_domain_suffix_pattern_from_grid_config(network, subnet_name)

print "*" * 70
print "Starts Tests"
print "*" * 70
suite = unittest.TestLoader().loadTestsFromTestCase(TestInterfaceAttach)
unittest.TextTestRunner(verbosity=2).run(suite)
print "*" * 70
print "End of Tests"
print "*" * 70

## Tears Down the Objects Created ###
s.interface_detach(s1.id,iface.port_id)
s.terminate_instance(instance)
s.delete_subnet(subnet_name)
s.delete_network(network)
