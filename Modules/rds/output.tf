output "instance_id" {
  value = aws_db_instance.tango_db.id
}
output "tangords_sg" {
  value = aws_security_group.tangords_sg.id
}

output "db_subnet_group_id" {
  value = aws_db_subnet_group.tango_Subgroup.id
}