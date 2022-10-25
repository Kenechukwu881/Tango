output "sg_cluster_id" {
  value = aws_security_group.tangoSG-cluster.id
}

output "eks_cluster_id" {
  value = aws_eks_cluster.tangoeks_cluster.id
}

output "eks_cluster" {
  value = aws_eks_cluster.tangoeks_cluster
}

output "nodegroup_id" {
  value = aws_eks_node_group.tango_nodegroup.id
}

output "iam_role" {
  value = aws_iam_role.tango-cluster.arn
}

output "iam_role_node" {
  value = aws_iam_role.tango-node.arn
}


locals {
  config_map_aws_auth = <<CONFIGMAPAWSAUTH


apiVersion: v1
kind: ConfigMap
metadata:
  name: aws-auth
  namespace: kube-system
data:
  mapRoles: |
    - rolearn: ${aws_iam_role.tango-node.arn}
      username: system:node:{{EC2PrivateDNSName}}
      groups:
        - system:bootstrappers
        - system:nodes
CONFIGMAPAWSAUTH

  kubeconfig = <<KUBECONFIG


apiVersion: v1
clusters:
- cluster:
    server: ${aws_eks_cluster.tangoeks_cluster.endpoint}
    certificate-authority-data: ${aws_eks_cluster.tangoeks_cluster.certificate_authority.0.data}
  name: kubernetes
contexts:
- context:
    cluster: kubernetes
    user: aws
  name: aws
current-context: aws
kind: Config
preferences: {}
users:
- name: aws
  user:
    exec:
      apiVersion: client.authentication.k8s.io/v1alpha1
      command: aws-iam-authenticator
      args:
        - "token"
        - "-i"
        - "${var.cluster-name}"
KUBECONFIG
}

output "config_map_aws_auth" {
  value = local.config_map_aws_auth
}

output "kubeconfig" {
  value = local.kubeconfig
}