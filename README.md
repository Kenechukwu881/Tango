# Tango
# Project to standup 2048-game test
# Using Terraform to provision a fully managed Amazon EKS Cluster

##### Prerequisite
+ AWS Acccount.
+ Create an ubuntu EC2 Instance or use your personal laptop.
+ Create IAM Role With Required Policies.
   + VPCFullAccess
   + EC2FullAcces
   + S3FullAccess  ..etc
   + Administrator Access
+ Attach IAM Role to EC2 Instance.
+ Install eksadmin
+ install terraform

# Initialise to install plugins
$ terraform init 
# Validate terraform scripts
$ terraform validate 
# Plan terraform scripts which will list resources which is going be created.
$ terraform plan 
# Apply to create resources
$ terraform apply --auto-approve

# Manage the kubeconfig file
- aws sts get-caller-identity
- aws eks update-kubeconfig --region region --name my_cluster

# Steps to follow
- Create the S3 bucket manually to store the Statefile and DynamoDB to lock the Statefile
- Create a terraform templates to deploy your AWS resources (maintain atleast 2AZs);
    - VPC (incl IGW, Subnets, Nat Gateway, EIP, Route table, RT Associations)
    - RDS (incl secrets in secret manager, security group, subnet group, sns, cloudwatch logs/metrics)
    - EKS (incl IAM roles (cluster and node), policy, security group (cluster and node), eks-cluster, sns, cloudwatch logs/metrics, node-group)
- Deploy containerized application as pod using the manifest file (including the networking tool, mysql service, secrets object)
- Setup helm, Prometheus and Grafana

