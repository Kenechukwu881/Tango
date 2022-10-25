variable "vpc_cidr_block" {
  default = ""
}

variable "instance_tenancy" {
  default = ""
  
}

variable "enable_dns_support" {
  default = ""
  
}

variable "enable_dns_hostnames" {
  default = ""
  
}

variable "subnet_pub_1a_cidr_block" {
  default = ""
}

variable "subnet_priv_1a_cidr_block" {
  default = ""
}

variable "subnet_priv_db_1a_cidr_block" {
  default = ""
}

variable "subnet_pub_1b_cidr_block" {
  default = ""
}

variable "subnet_priv_1b_cidr_block" {
  default = ""
}

variable "subnet_priv_db_1b_cidr_block" {
  default = ""
}

variable "vpc_tag_name" {
  default = ""
}

variable "vpc_tag_environment" {
  default = ""
}

variable "subnet_1a_az" {
  default = ""
}

variable "subnet_1b_az" {
  default = ""
}

variable "aws_region" {
  description = "AWS region for all resources."
  type    = string
  default = "us-east-1"
}

variable "region" {
  description = "The AWS Region to use"
  type = string  
  default = ""
}

variable "internet_gateway_name" {
  description = "internet_gateway_name"
  type = string  
  default = ""
  
}

variable "nat_gateway_a_name" {
  description = "The nat_gateway_a_name"
  type = string  
  default = ""
  
}

variable "public_route_name" {
  description = "The public_route_name"
  type = string  
  default = ""
  
}

variable "private_route_a_name" {
  description = "The private_route_a_name"
  type = string  
  default = ""
  
}

variable "private_route_b_name" {
  description = "The private_route_b_name"
  type = string  
  default = ""
  
}

variable "map_public_ip_on_launch" {
  description = "Should public ip be mapped on launch"
  type = string  
  default = ""
  
}

variable "public_subnet_1a_name" {
  description = "The public_subnet_1a_name"
  type = string  
  default = ""
  
}

variable "private_subnet_1a_name" {
  description = "The private_subnet_1a_name"
  type = string  
  default = ""
  
}

variable "private_db_subnet_1a_name" {
  description = "The private_db_subnet_1a_name"
  type = string  
  default = ""
  
}

variable "public_subnet_1b_name" {
  description = "The public_subnet_1b_name"
  type = string  
  default = ""
  
}

variable "private_subnet_1b_name" {
  description = "The private_subnet_1b_name"
  type = string  
  default = ""
  
}

variable "private_db_subnet_1b_name" {
  description = "The private_db_subnet_1b_name"
  type = string  
  default = ""
  
}

