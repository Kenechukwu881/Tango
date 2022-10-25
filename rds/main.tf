module "rds" {
    source = "../modules/rds"
    eks_tag_environment= var.eks_tag_environment
    sg_name = var.sg_name
    rds_name = var.rds_name
    subnet_group = var.subnet_group
    aws_region = var.aws_region

}