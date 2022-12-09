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

# Detailed steps
- Create the S3 bucket manually to store the Statefile and DynamoDB to lock the Statefile
- Create a terraform templates to deploy your AWS resources (maintain atleast 2AZs);
    - VPC (incl IGW, Subnets, Nat Gateway, EIP, Route table, RT Associations)
    - RDS (incl secrets in secret manager, security group, subnet group, sns, cloudwatch logs/metrics)
    - EKS (incl IAM roles (cluster and node), policy, security group (cluster and node), eks-cluster, sns, cloudwatch logs/metrics, node-group)

# More terrafom commands
terraform plan --var-file=variable/stage.tfvars
terraform apply --var-file=variable/stage.tfvars --auto-approve

### run below commands after deploying the above resources
- aws sts get-caller-identity
- aws eks update-kubeconfig --region us-east-1 --name tangoeks_cluster
- kubectl get svc ##To make sure you can talk to the cluster through your machine

--------------------------------------------
<!-- # Testing new changes to the cluster, and enabling AWS Load Balancer Controller
# download an IAM policy that allows the AWS Load Balancer Controller to make calls to AWS APIs on your behalf
- curl -o iam_policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.4.1/docs/install/iam_policy.json
# create an IAM policy using the policy that you downloaded in step 3
- aws iam create-policy --policy-name AWSLoadBalancerControllerIAMPolicy --policy-document file://iam_policy.json
# create a service account named aws-load-balancer-controller in the kube-system namespace for the AWS Load Balancer Controller
- kubectl apply -f service.yml
# verify that the new service role was created
- kubectl get serviceaccount aws-load-balancer-controller --namespace game-2048
# Install the AWS Load Balancer Controller using Helm
- helm repo add eks https://aws.github.io/eks-charts
- kubectl apply -k "github.com/aws/eks-charts/stable/aws-load-balancer-controller//crds?ref=master"
    - git submodule deinit -f . && git submodule update --init --recursive
    - git submodule update --init --recursive
- helm install aws-load-balancer-controller eks/aws-load-balancer-controller --set clusterName=tangoeks_cluster --set serviceAccount.create=false --set region=us-east-1 --set vpcId=vpc-0fce1d14275000a7a --set serviceAccount.name=aws-load-balancer-controller -n game-2048 -->

-----------------------------------------------------
curl -o iam_policy_us-gov.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.4.4/docs/install/iam_policy_us-gov.json
aws iam create-policy --policy-name AWSLoadBalancerControllerIAMPolicy --policy-document file://iam_policy.json
aws eks describe-cluster --name tangoeks_cluster --query "cluster.identity.oidc.issuer" --output text

cat >load-balancer-role-trust-policy.json <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Federated": "arn:aws:iam::231596626862:oidc-provider/oidc.eks.us-east-1.amazonaws.com/id/7C75D9B4D2FB97CBDCE80913F31D63D7"
            },
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Condition": {
                "StringEquals": {
                    "oidc.eks.us-east-1.amazonaws.com/id/7C75D9B4D2FB97CBDCE80913F31D63D7:aud": "sts.amazonaws.com",
                    "oidc.eks.us-east-1.amazonaws.com/id/7C75D9B4D2FB97CBDCE80913F31D63D7:sub": "system:serviceaccount:kube-system:aws-load-balancer-controller"
                }
            }
        }
    ]
}
EOF

aws iam create-role --role-name AmazonEKSLoadBalancerControllerRole --assume-role-policy-document file://"load-balancer-role-trust-policy.json"
aws iam attach-role-policy --policy-arn arn:aws:iam::231596626862:policy/AWSLoadBalancerControllerIAMPolicy --role-name AmazonEKSLoadBalancerControllerRole

cat >aws-load-balancer-controller-service-account.yaml <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  labels:
    app.kubernetes.io/component: controller
    app.kubernetes.io/name: aws-load-balancer-controller
  name: aws-load-balancer-controller
  namespace: kube-system
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::231596626862:role/AmazonEKSLoadBalancerControllerRole
EOF
kubectl apply -f aws-load-balancer-controller-service-account.yaml


helm repo add eks https://aws.github.io/eks-charts
helm repo update


602401143452.dkr.ecr.region-code.amazonaws.com/amazon/aws-load-balancer-controller:v2.4.4


            aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 602401143452.dkr.ecr.us-east-1.amazonaws.com

            docker pull 602401143452.dkr.ecr.us-east-1.amazonaws.com/amazon/aws-load-balancer-controller:v2.4.5

            docker tag 9387180215c20d661fa3f4a718bafce0dda1dd1df0bae2d16efb03d08ff978f7 231596626862.dkr.ecr.us-east-1.amazonaws.com/eks-testing

            aws ecr get-login-password --region us-east-1 | docker login --username AWS --password-stdin 231596626862.dkr.ecr.us-east-1.amazonaws.com/eks-testing

            docker push 231596626862.dkr.ecr.us-east-1.amazonaws.com/eks-testing

kubectl create secret docker-registry albcred \
  --docker-server=231596626862.dkr.ecr.us-east-1.amazonaws.com \
  --docker-username=AWS \
  --docker-password=$(aws ecr get-login-password) \
  --namespace=kube-system

kubectl apply -k crd  # always check the latest update(github.com/aws/eks-charts/stable/aws-load-balancer-controller//crds?ref=master)

helm install aws-load-balancer-controller eks/aws-load-balancer-controller -n kube-system  -f alb.yml --set clusterName=tangoeks_cluster --set serviceAccount.create=false --set serviceAccount.name=aws-load-balancer-controller --set region=us-east-1 --set vpcId=vpc-0fce1d14275000a7a

helm upgrade aws-load-balancer-controller eks/aws-load-balancer-controller -n kube-system  -f alb.yml --set clusterName=tangoeks_cluster --set serviceAccount.create=false --set serviceAccount.name=aws-load-balancer-controller --set region=us-east-1 --set vpcId=vpc-0fce1d14275000a7a

kubectl get deployment -n kube-system aws-load-balancer-controller

kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.4.1/docs/examples/2048/2048_full.yaml

helm delete aws-load-balancer-controller -n kube-system
helm repo remove nginx-stable
helm repo list
helm search repo
helm show values eks/aws-load-balancer-controller

kubectl get event -n game-2048

kubectl logs -n kube-system deployment.apps/aws-load-balancer-controller

kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.4.4/docs/examples/2048/2048_full.yaml

kubectl delete -f https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.4.4/docs/examples/2048/2048_full.yaml

kubectl get ingress/ingress-2048 -n game-2048




----------------------------------------------------------------------
- deploy mysql service and establish connection
    - create namespace ##kubectl create namespace game-2048
    - kubectl apply -f mysql.yml
    - kubectl run -it --rm --image=mysql:5.7.38 --restart=Never mysql-client -- mysql -h tangodb.ckuubfdcqv8s.us-east-1.rds.amazonaws.com -u adminaccount -pVYYoesZbzfLcgonc
- Deploy the secrets.yml
    - kubectl apply -f secrets.yml
- Deploy the Nginx Ingress controller
    - curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
    - sudo chmod 700 get_helm.sh
    - ./get_helm.sh
    - helm repo add nginx-stable https://helm.nginx.com/stable
    - helm repo update
    - helm search repo nginx-stable
    - helm install -n game-2048 nginx-stable nginx-stable/nginx-ingress

      or
    - kubectl apply -f https://raw.githubusercontent.com/kubernetes/ingress-nginx/controller-v1.3.0/deploy/static/provider/cloud/deploy.yaml ##install nginx ingress controller

      or
    - helm upgrade --install ingress-nginx ingress-nginx --repo https://kubernetes.github.io/ingress-nginx --namespace game-2048 --create-namespace  ##install nginx controller using helm

      or
    - curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
    - sudo chmod 700 get_helm.sh
    - ./get_helm.sh
    - controller_tag=$(curl -s https://api.github.com/repos/kubernetes/ingress-nginx/releases/latest | grep tag_name | cut -d '"' -f 4)
    - wget https://github.com/kubernetes/ingress-nginx/archive/refs/tags/${controller_tag}.tar.gz
    - tar xvf ${controller_tag}.tar.gz
    - cd ingress-nginx-${controller_tag}
    - cd charts/ingress-nginx/
    - helm install -n game-2048 ingress-nginx  -f values.yaml .
   
   
   
   
    - kubectl --namespace game-2048 get services -o wide -w ingress-nginx-controller
    - kubectl get pods --all-namespaces
    - kubectl get all -n game-2048
    - kubectl get pods -n game-2048
    - kubectl -n game-2048 logs deploy/ingress-nginx-controller ##check logs in the pod
    - kubectl -n game-2048 logs deploy/ingress-nginx-controller -f
    - kubectl get pods --namespace game-2048 
    - helm -n game-2048 uninstall ingress-nginx ##remove ingress controller

    - kubectl delete all  --all -n game-2048
    - kubectl delete ingress/ingress-2048 -n game-2048

- Deploy the manifest file
    - kubectl apply -f manifest.yml
    - kubectl edit ingress -n game-2048 ##edit the ingress rule
    - kubectl logs pod/nginx-stable-nginx-ingress-b9455b445-vj9kt -n game-2048 ##check the pod
- Deploy containerized application as pod using the manifest file (including the networking tool, mysql service, secrets object)
- Deploy Prometheus and Grafana
    - kubectl create namespace prometheus
    - helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
    - helm repo update
    - helm install studio-prom prometheus-community/kube-prometheus-stack  ##This has the server, alert manager and grafana as a bundle
    - kubectl --namespace default get pods -l "release=studio-prom"
    - kubectl get pods
    - kubectl get services
    - kubectl port-forward deployment/studio-prom-grafana 3000  ##Test grafana is installed
        - user: admin
        - pass: prom-operator
