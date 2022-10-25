###################################################
######### Outputs used for other TF Code ##########
###################################################
output "id" {
  value = aws_vpc.tangovpc.id
}

output "pub_subnet_1a_id" {
  value = aws_subnet.tangopublic_1a.id
}


output "pub_subnet_1b_id" {
  value = aws_subnet.tangopublic_1b.id
}

output "priv_subnet_1a_id" {
  value = aws_subnet.tangoprivate_1a.id
}

output "priv_subnet_1b_id" {
  value = aws_subnet.tangoprivate_1b.id
}

output "priv_db_subnet_1a_id" {
  value = aws_subnet.tango_db_1a.id
}

output "priv_db_subnet_1b_id" {
  value = aws_subnet.tango_db_1b.id
}