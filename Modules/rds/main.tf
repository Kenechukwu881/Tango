#To maintain a high availability, you will need to create an rds cluster.
#Due to the assignement, i will be creating just a single rds to demonstrate the project
resource "random_password" "password" {
  length           = 16
  special          = false
}
 
resource "aws_secretsmanager_secret" "secretmasterDB" {
   name = "Tango-z"
   tags = {               
    Environment = var.eks_tag_environment                    
  }
}

resource "aws_secretsmanager_secret_version" "tango-version" {
  secret_id = aws_secretsmanager_secret.secretmasterDB.id
  secret_string = <<EOF
   {
    "username": "adminaccount",
    "password": "${random_password.password.result}"
   }
EOF
}
 
data "aws_secretsmanager_secret" "secretmasterDB" {
  arn = aws_secretsmanager_secret.secretmasterDB.arn
}
 
data "aws_secretsmanager_secret_version" "creds" {
  secret_id = data.aws_secretsmanager_secret.secretmasterDB.arn
}
 
locals {
  db_creds = jsondecode(data.aws_secretsmanager_secret_version.creds.secret_string)
}

data "aws_vpc" "tangovpc" {
  filter {
    name = "tag:Name"
    values = ["Staging tangoVPC"]
  }
}
data "aws_subnet_ids" "db_subnet"{
  vpc_id = "${data.aws_vpc.tangovpc.id}"
  filter {
    name = "tag:Name"
    values = ["staging_tango_db_1a","staging_tango_db_1b"]
  }
}
resource "aws_security_group" "tangords_sg" {
  description = "Allow access for RDS Database on Port 3306"
  vpc_id      = "${data.aws_vpc.tangovpc.id}"
  ingress {
    from_port   = 3306
    to_port     = 3306
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] #change to 0.0.0.0/0 to allow access from everywhere
  }
  tags = {
    Name = var.sg_name                 
    Environment = var.eks_tag_environment                    
  }
}

resource "aws_db_subnet_group" "tango_Subgroup" {
  description = "EKS RDS DB Subnet Group"
  subnet_ids = [sort(data.aws_subnet_ids.db_subnet.ids)[0],sort(data.aws_subnet_ids.db_subnet.ids)[1]]
  tags = {
    Environment = var.eks_tag_environment 
    Name = var.subnet_group 
  }
}

resource "aws_db_instance" "tango_db" {
  allocated_storage = 10
  identifier = "tangodb"
  storage_type = "gp2"
  engine = "mysql"
  engine_version = "5.7"
  instance_class = "db.t2.small"
  vpc_security_group_ids = [aws_security_group.tangords_sg.id]
  username = local.db_creds.username
  password = local.db_creds.password
  db_subnet_group_name = aws_db_subnet_group.tango_Subgroup.name
  parameter_group_name = "default.mysql5.7"
  skip_final_snapshot  = true
  publicly_accessible = true
    tags = {
    Terraform   = "true"
    Environment = var.eks_tag_environment 
    Name = var.rds_name 
  }
}

resource "aws_sns_topic" "cloudwatch_updates" {
    name = "cloudwatch_rds_updates"
}

resource "aws_sns_topic_subscription" "cloudwatch_email_sub" {
  topic_arn = aws_sns_topic.cloudwatch_updates.arn
  protocol  = "email"
  endpoint  = "akabuezeobumneme@gmail.com"
}

resource "aws_cloudwatch_log_group" "tango_rds" {
  name = "/aws/rds/${var.rds_name}"
  retention_in_days = 7
  tags = {
    Environment = var.eks_tag_environment
  }
}
resource "aws_cloudwatch_metric_alarm" "CPUUtilization" {
  alarm_name                = "cpu-rds-alarm"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "5"
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/RDS"
  period                    = "30"
  statistic                 = "Maximum"
  threshold                 = "50"
  alarm_description         = "This metric monitors RDS CPU utilization"
  alarm_actions             = [aws_sns_topic.cloudwatch_updates.arn]
  insufficient_data_actions = []
   dimensions = {
      DBInstanceIdentifier = aws_db_instance.tango_db.id
   }
}