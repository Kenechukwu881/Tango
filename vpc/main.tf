module "vpc" {
    source = "../modules/vpc"
    vpc_cidr_block = var.vpc_cidr_block
    instance_tenancy= var.instance_tenancy
    enable_dns_support = var.enable_dns_support
    enable_dns_hostnames = var.enable_dns_hostnames 
    subnet_pub_1a_cidr_block = var.subnet_pub_1a_cidr_block
    subnet_priv_1a_cidr_block = var.subnet_priv_1a_cidr_block
    subnet_priv_db_1a_cidr_block = var.subnet_priv_db_1a_cidr_block
    subnet_pub_1b_cidr_block = var.subnet_pub_1b_cidr_block
    subnet_priv_1b_cidr_block = var.subnet_priv_1b_cidr_block
    subnet_priv_db_1b_cidr_block = var.subnet_priv_db_1b_cidr_block
    vpc_tag_name = var.vpc_tag_name
    vpc_tag_environment = var.vpc_tag_environment
    subnet_1a_az = var.subnet_1a_az
    subnet_1b_az = var.subnet_1b_az
    internet_gateway_name =var.internet_gateway_name               
    nat_gateway_a_name =var.nat_gateway_a_name                      
    public_route_name =  var.public_route_name       
    private_route_a_name = var.private_route_a_name            
    private_route_b_name = var.private_route_b_name    
    map_public_ip_on_launch = var.map_public_ip_on_launch                     
    public_subnet_1a_name =  var.public_subnet_1a_name          
    private_subnet_1a_name =  var.private_subnet_1a_name            
    private_db_subnet_1a_name = var.private_db_subnet_1a_name          
    public_subnet_1b_name  = var.public_subnet_1b_name                 
    private_subnet_1b_name  =   var.private_subnet_1b_name            
    private_db_subnet_1b_name = var.private_db_subnet_1b_name 

}