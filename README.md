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

### run below commands after deploying the above resources
- aws sts get-caller-identity
- aws eks update-kubeconfig --region us-east-1 --name tangoeks_cluster
- kubectl get svc ##To make sure you can talk to the cluster through your machine
- deploy mysql service and establish connection
    - create namespace ##kubectl create namespace game-2048
    - kubectl apply -f mysql.yml
    - kubectl run -it --rm --image=mysql:5.7.38 --restart=Never mysql-client -- mysql -h tangodb.ckuubfdcqv8s.us-east-1.rds.amazonaws.com -u adminaccount -pVYYoesZbzfLcgonc
- Deploy the secrets.yml
    - kubectl apply -f secrets.yml
- Deploy the Nginx Ingress controller
    a)
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
        - kubectl get all -n game-2048
        - kubectl get pods -n game-2048
        - kubectl -n game-2048 logs deploy/ingress-nginx-controller ##check logs in the pod
        - kubectl -n game-2048 logs deploy/ingress-nginx-controller -f
        - kubectl get pods --namespace game-2048 
        - helm -n game-2048 uninstall ingress-nginx ##remove ingress controller

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