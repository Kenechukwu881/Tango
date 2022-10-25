vpc_cidr_block = "10.130.0.0/16"

instance_tenancy  = "default"

enable_dns_support = "true"

enable_dns_hostnames = "true"

vpc_tag_name = "Staging tangoVPC"

vpc_tag_environment = "staging"

subnet_1a_az = "us-east-1a"

subnet_1b_az = "us-east-1b"

subnet_pub_1a_cidr_block = "10.130.10.0/24"

subnet_priv_1a_cidr_block = "10.130.100.0/24"

subnet_priv_db_1a_cidr_block = "10.130.200.0/24"

subnet_pub_1b_cidr_block = "10.130.15.0/24"

subnet_priv_1b_cidr_block = "10.130.150.0/24"

subnet_priv_db_1b_cidr_block = "10.130.250.0/24"

region = "us-east-1"

internet_gateway_name = "staging_tangoIGW"
nat_gateway_a_name = "staging_tangoNat"
public_route_name =  "staging_tangopub_Route"
private_route_a_name = "staging_tango_Route_A"
private_route_b_name = "staging_tango__Route_B"
map_public_ip_on_launch = "true"
public_subnet_1a_name =  "staging_tango_public_1a"
private_subnet_1a_name =  "staging_tango_private_1a"
private_db_subnet_1a_name = "staging_tango_db_1a"
public_subnet_1b_name  = "staging_tango_public_1b"
private_subnet_1b_name  =   "staging_tango_private_1b"
private_db_subnet_1b_name = "staging_tango_db_1b"
