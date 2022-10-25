###################################################
######### Outputs used for other TF Code ##########
###################################################
output "id" {
  value = module.vpc.id
}

output "pub_subnet_1a_id" {
  value = module.vpc.pub_subnet_1a_id
}

output "pub_subnet_1b_id" {
  value = module.vpc.pub_subnet_1b_id
}

output "priv_subnet_1a_id" {
  value = module.vpc.priv_subnet_1a_id
}

output "priv_subnet_1b_id" {
  value = module.vpc.priv_db_subnet_1b_id
}

output "priv_db_subnet_1a_id" {
  value = module.vpc.priv_db_subnet_1a_id
}

output "priv_db_subnet_1b_id" {
  value = module.vpc.priv_db_subnet_1b_id
}
