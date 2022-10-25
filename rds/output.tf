output "instance_id" {
  value = module.rds.instance_id
}
output "tangords_sg" {
  value = module.rds.tangords_sg
}

output "db_subnet_group_id" {
  value = module.rds.db_subnet_group_id
}