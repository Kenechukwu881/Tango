# EKS Cluster Resources
#  * IAM Role to allow EKS service to manage other AWS services
#  * EC2 Security Group to allow networking traffic with EKS cluster
#  * EKS Cluster
#

resource "aws_iam_role" "tango-cluster" {
  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "eks.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
  tags = {
    Name = var.iam_role_name                 
    Environment = var.eks_tag_environment                    
  }
}

resource "aws_iam_role_policy_attachment" "tango-cluster-AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.tango-cluster.name
}

resource "aws_iam_role_policy_attachment" "tango-cluster-AmazonEKSServicePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSServicePolicy"
  role       = aws_iam_role.tango-cluster.name
}

resource "aws_iam_role_policy_attachment" "tango-cluster-AmazonVPCFullAccess" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonVPCFullAccess"
  role       = aws_iam_role.tango-cluster.name
}
data "aws_vpc" "tangovpc" {
  filter {
    name = "tag:Name"
    values = ["Staging tangoVPC"]
  }
}
data "aws_subnet_ids" "public"{
  vpc_id = "${data.aws_vpc.tangovpc.id}"
  filter {
    name = "tag:Name"
    values = ["staging_tango_public_1a","staging_tango_public_1b"]
  }
}

resource "aws_security_group" "tangoSG-cluster" {
  description = "Cluster communication with worker nodes"
  vpc_id      = "${data.aws_vpc.tangovpc.id}"
  ingress {
    from_port   = 6443 #kubernetes API Server
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

   ingress {
    from_port   = 2379 #etcd server client api
    to_port     = 2380
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 10250 #kubelet api
    to_port     = 10250
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 10251 #kube-shceduler
    to_port     = 10251
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 10252 #kube-controller-manager
    to_port     = 10252
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  ingress {
    from_port   = 30000 #NodePort
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = var.sg_name                 
    Environment = var.eks_tag_environment                    
  }
}

resource "aws_security_group_rule" "demo-cluster-ingress-workstation-https" {
  cidr_blocks       = [local.workstation-external-cidr]
  description       = "Allow workstation to communicate with the cluster API Server"
  from_port         = 443
  protocol          = "tcp"
  security_group_id = aws_security_group.tangoSG-cluster.id
  to_port           = 443
  type              = "ingress"
}

resource "aws_eks_cluster" "tangoeks_cluster" {
  name     = var.cluster-name
  version = var.cluster-version
  role_arn = aws_iam_role.tango-cluster.arn

  vpc_config {
    security_group_ids = [aws_security_group.tangoSG-cluster.id]
    subnet_ids = [sort(data.aws_subnet_ids.public.ids)[0],sort(data.aws_subnet_ids.public.ids)[1]]
  }

  depends_on = [
    aws_iam_role_policy_attachment.tango-cluster-AmazonEKSClusterPolicy,
    aws_iam_role_policy_attachment.tango-cluster-AmazonEKSServicePolicy,
    aws_iam_role_policy_attachment.tango-cluster-AmazonVPCFullAccess,
    aws_cloudwatch_log_group.tango_cloudwatch,
  ]
  enabled_cluster_log_types = ["api", "audit", "authenticator", "controllerManager", "scheduler"]
}

resource "aws_cloudwatch_log_group" "tango_cloudwatch" {
  name = "/aws/eks/${var.cluster-name}/cluster"
  retention_in_days = 7
    tags = {
    Environment = var.eks_tag_environment
  }
}
resource "aws_sns_topic" "cloudwatch_nodes" {
    name = "cloudwatch_nodes"
}

resource "aws_sns_topic_subscription" "cloudwatch_email_sub" {
  topic_arn = aws_sns_topic.cloudwatch_nodes.arn
  protocol  = "email"
  endpoint  = "akabuezeobumneme@gmail.com"
}

resource "aws_cloudwatch_metric_alarm" "CPUUtilization" {
  alarm_name                = "cpu-node-alarm"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = "5"
  metric_name               = "CPUUtilization"
  namespace                 = "AWS/RDS"
  period                    = "30"
  statistic                 = "Maximum"
  threshold                 = "50"
  alarm_description         = "This metric monitors Node CPU utilization"
  alarm_actions             = [aws_sns_topic.cloudwatch_nodes.arn]
  insufficient_data_actions = []
   dimensions = {
      InstanceId = "aws_eks_node_group.tango_nodegroup"
   }
}

# EKS Worker Nodes Resources
#  * IAM role allowing Kubernetes actions to access other AWS services
#  * EKS Node Group to launch worker nodes
#

resource "aws_iam_role" "tango-node" {
  assume_role_policy = <<POLICY
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Service": "ec2.amazonaws.com"
      },
      "Action": "sts:AssumeRole"
    }
  ]
}
POLICY
  tags = {
    Name = var.iam_role_node_name                
    Environment = var.eks_tag_environment                    
  }
}

data "aws_iam_policy_document" "worker_autoscaling" {
  statement {
    sid    = "eksWorkerAutoscalingAll"
    effect = "Allow"

    actions = [
      "autoscaling:DescribeAutoScalingGroups",
      "autoscaling:DescribeAutoScalingInstances",
      "autoscaling:DescribeLaunchConfigurations",
      "autoscaling:DescribeTags",
      "ec2:DescribeLaunchTemplateVersions",
    ]

    resources = ["*"]
  }

  statement {
    sid    = "eksWorkerAutoscalingOwn"
    effect = "Allow"

    actions = [
      "autoscaling:SetDesiredCapacity",
      "autoscaling:TerminateInstanceInAutoScalingGroup",
      "autoscaling:UpdateAutoScalingGroup",
    ]

    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "autoscaling:ResourceTag/kubernetes.io/cluster/${aws_eks_cluster.tangoeks_cluster.id}"
      values   = ["owned"]
    }

    condition {
      test     = "StringEquals"
      variable = "autoscaling:ResourceTag/k8s.io/cluster-autoscaler/enabled"
      values   = ["true"]
    }
  }
}

resource "aws_iam_policy" "worker_autoscaling" {
  name_prefix = "eks-worker-autoscaling-${aws_eks_cluster.tangoeks_cluster.id}"
  description = "EKS worker node autoscaling policy for cluster ${aws_eks_cluster.tangoeks_cluster.id}"
  policy      = data.aws_iam_policy_document.worker_autoscaling.json
}

resource "aws_iam_role_policy_attachment" "workers_autoscaling" {
  policy_arn = aws_iam_policy.worker_autoscaling.arn
  role       = aws_iam_role.tango-node.name
}

resource "aws_iam_role_policy_attachment" "tango-node-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.tango-node.name
}

resource "aws_iam_role_policy_attachment" "tango-node-AmazonSSMFullAccess" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMFullAccess"
  role       = aws_iam_role.tango-node.name
}

resource "aws_iam_role_policy_attachment" "tango-node-ElasticLoadBalancingFullAccess" {
  policy_arn = "arn:aws:iam::aws:policy/ElasticLoadBalancingFullAccess"
  role       = aws_iam_role.tango-node.name
}

resource "aws_iam_role_policy_attachment" "tango-node-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.tango-node.name
}

resource "aws_iam_role_policy_attachment" "tango-node-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.tango-node.name
}

resource "aws_eks_node_group" "tango_nodegroup" {
  cluster_name    = var.cluster-name
  node_group_name = var.node_group_name
  node_role_arn   = aws_iam_role.tango-node.arn
  subnet_ids      = [sort(data.aws_subnet_ids.public.ids)[0],sort(data.aws_subnet_ids.public.ids)[1]]
  instance_types = [var.eks_node_instance_type]

  scaling_config {
    desired_size = 2
    max_size = 4
    min_size = 2
  }

  depends_on = [
    aws_iam_role_policy_attachment.workers_autoscaling,
    aws_iam_role_policy_attachment.tango-node-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.tango-node-ElasticLoadBalancingFullAccess,
    aws_iam_role_policy_attachment.tango-node-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.tango-node-AmazonEC2ContainerRegistryReadOnly,
    aws_iam_role_policy_attachment.tango-node-AmazonSSMFullAccess,
  ]
  tags = {
    Name = var.node_name                
    Environment = var.eks_tag_environment                    
  }
}


locals {
  k8s_service_account_name      = "iam-role-test-SA"
  k8s_service_account_namespace = "game-2048"

  # Get the EKS OIDC Issuer without https:// prefix
  eks_oidc_issuer = trimprefix(aws_eks_cluster.tangoeks_cluster.identity[0].oidc[0].issuer, "https://")
}

# Get the caller identity so that we can get the AWS Account ID

data "aws_caller_identity" "current" {}

# Get the EKS cluster we want to target

# data "aws_eks_cluster" "tangoeks_cluster" {
#   name = var.cluster-name
# }

# Create the IAM role that will be assumed by the service account

resource "aws_iam_role" "iam_role" {
  name               = "iam-role"
  assume_role_policy = data.aws_iam_policy_document.iam_role.json
}

# Create IAM policy allowing the k8s service account to assume the IAM role

data "aws_iam_policy_document" "iam_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type = "Federated"
      identifiers = [
        "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${local.eks_oidc_issuer}"
      ]
    }

    # Limit the scope so that only our desired service account can assume this role
    condition {
      test     = "StringEquals"
      variable = "${local.eks_oidc_issuer}:sub"
      values = [
        "system:serviceaccount:${local.k8s_service_account_namespace}:${local.k8s_service_account_name}"
      ]
    }
  }
}