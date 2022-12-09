variable "cluster-name" {
  type = string
  default = ""
}

variable "cluster-version" {
  type = string
  default = ""
}

variable "eks_node_instance_type" {
  type = string
  default = ""
}

variable "eks_tag_environment" {
  type = string
  default = ""
}

variable "iam_role_name" {
  type = string
  default = ""
}

variable "iam_role_node_name" {
  type = string
  default = ""
}

variable "sg_name" {
  type = string
  default = ""
}

variable "node_group_name" {
  type = string
  default = ""
}

variable "aws_region" {
  type = string
  default = ""
}

variable "node_name" {
  type    = string
  default = ""
}