variable "cluster-name" {
  type    = string
}

variable "cluster-version" {
  type    = string
}

variable "eks_node_instance_type" {
  type = string
}

variable "eks_tag_environment" {
  type = string
}

variable "iam_role_name" {
  type = string
}

variable "iam_role_node_name" {
  type = string
}

variable "sg_name" {
  type = string
}

variable "node_group_name" {
  type    = string
}
variable "node_name" {
  type    = string
}