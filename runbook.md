##### Important Links
+ https://docs.aws.amazon.com/eks/latest/userguide/aws-load-balancer-controller.html
+ https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.4/
+ https://kubernetes-sigs.github.io/aws-load-balancer-controller/v2.4/how-it-works/
+ https://docs.aws.amazon.com/eks/latest/userguide/alb-ingress.html
+ https://docs.aws.amazon.com/eks/latest/userguide/network-load-balancing.html
+ https://docs.aws.amazon.com/eks/latest/userguide/enable-iam-roles-for-service-accounts.html
+ https://docs.aws.amazon.com/eks/latest/userguide/eksctl.html
+ https://aws.amazon.com/premiumsupport/knowledge-center/eks-alb-ingress-controller-fargate/
+ https://skryvets.com/blog/2021/03/15/kubernetes-pull-image-from-private-ecr-registry/
+ https://docs.aws.amazon.com/eks/latest/userguide/add-ons-images.html


##### Prerequisite
+ Review above links before you start
+ AWS Acccount.
+ install terraform
+ install docker
+ install git
+ install kubectl
+ install eksctl (https://docs.aws.amazon.com/eks/latest/userguide/eksctl.html)
+ AWS CLI installed and configured on your device
+ Install latest versions of all the tools/software above

#### Detailed steps
- Create a terraform templates to deploy your AWS resources (maintain atleast 2AZs);
    - VPC (incl IGW, Subnets, Nat Gateway, EIP, Route table, RT Associations)
        - make sure to maintain 2subnets per private and public
        - remember to add tags to the subnets associated with the worker Nodes for the AWS Load Balancer controller
        - public subnet
            - key = kubernetes.io/role/elb; value is blank or 1
        - private
            - key = kubernetes.io/role/internal-elb; value is blank or 1
        - common tag for both
            - key = kubernetes.io/cluster/${cluster-name}; value is either "owned" or "shared"
    - EKS (incl IAM roles (cluster and node), policy, security group (cluster and node), eks-cluster, sns, cloudwatch logs/metrics, node-group)
        - atleast 2 worker nodes
    - Setup Helm by running the script (or referencing the helm link; https://helm.sh/docs/intro/install/)

#### run below commands after deploying the above resources
- aws sts get-caller-identity
- aws eks update-kubeconfig --region region-code --name my-cluster
- kubectl get svc ##To make sure you can talk to the cluster through your machine
- Install the AWS Load Balancer Controller (https://docs.aws.amazon.com/eks/latest/userguide/aws-load-balancer-controller.html) using Helm V3
    - Add an existing AWS Identity and Access Management (IAM) OpenID Connect (OIDC) provider for your cluster(https://docs.aws.amazon.com/eks/latest/userguide/enable-iam-roles-for-service-accounts.html)
    - Ensure that your Amazon VPC CNI plugin for Kubernetes, kube-proxy, and CoreDNS add-ons are at the minimum versions listed in Service account tokens (https://docs.aws.amazon.com/eks/latest/userguide/service-accounts.html#boundserviceaccounttoken-validated-add-on-versions).
    - Create an IAM Policy
        - curl -o iam_policy.json https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.4.4/docs/install/iam_policy.json [---> Download the Policy]
        - aws iam create-policy --policy-name AWSLoadBalancerControllerIAMPolicy --policy-document file://iam_policy.json  [---> create the IAM Policy]
    - Create an IAM Role (this will be associated later with the Kubernetes Service Account)
        - aws eks describe-cluster --name my-cluster --query "cluster.identity.oidc.issuer" --output text [---> View your cluster OIDC provider url]
        - cat >load-balancer-role-trust-policy.json <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Principal": {
                "Federated": "arn:aws:iam::111122223333:oidc-provider/oidc.eks.region-code.amazonaws.com/id/EXAMPLED539D4633E53DE1B71EXAMPLE"
            },
            "Action": "sts:AssumeRoleWithWebIdentity",
            "Condition": {
                "StringEquals": {
                    "oidc.eks.region-code.amazonaws.com/id/EXAMPLED539D4633E53DE1B71EXAMPLE:aud": "sts.amazonaws.com",
                    "oidc.eks.region-code.amazonaws.com/id/EXAMPLED539D4633E53DE1B71EXAMPLE:sub": "system:serviceaccount:kube-system:aws-load-balancer-controller"
                }
            }
        }
    ]
}
EOF [---> this will create the load-balancer-role-trust-policy. Replace 111122223333 with your account ID. Replace region-code with the AWS Region that your cluster is in.. Replace EXAMPLED539D4633E53DE1B71EXAMPLE with the output returned in the previous step]
        - aws iam create-role --role-name AmazonEKSLoadBalancerControllerRole --assume-role-policy-document file://"load-balancer-role-trust-policy.json" [---> this will create the IAM Role]
        - aws iam attach-role-policy --policy-arn arn:aws:iam::111122223333:policy/AWSLoadBalancerControllerIAMPolicy --role-name AmazonEKSLoadBalancerControllerRole [---> Attach the required Amazon EKS managed IAM policy to the IAM role. Replace 111122223333 with your account ID.]
    - Create the Kubernetes Service Account and associate it with the IAM Role
        - cat >aws-load-balancer-controller-service-account.yaml <<EOF
apiVersion: v1
kind: ServiceAccount
metadata:
  labels:
    app.kubernetes.io/component: controller
    app.kubernetes.io/name: aws-load-balancer-controller
  name: aws-load-balancer-controller
  namespace: kube-system
  annotations:
    eks.amazonaws.com/role-arn: arn:aws:iam::111122223333:role/AmazonEKSLoadBalancerControllerRole
EOF [---> Replace 111122223333 with your account ID]
        - kubectl apply -f aws-load-balancer-controller-service-account.yaml [---> creake the kubernetes service account]
    - Uninstall the AWS ALB Ingress Controller or 0.1.x version of the AWS Load Balancer Controller (only if installed with Helm). Complete the procedure using the tool that you originally installed it with. The AWS Load Balancer Controller replaces the functionality of the AWS ALB Ingress Controller for Kubernetes.
        - helm delete aws-alb-ingress-controller -n kube-system [---> Uninstall incubator/aws-alb-ingress-controller]
        - helm delete aws-load-balancer-controller -n kube-system [---> Uninstall eks-charts/aws-load-balancer-controller]
        - kubectl delete -f ingresscontroller-deploy.yaml
    - Install the AWS Load Balancer Controller
        - helm repo add eks https://aws.github.io/eks-charts [---> create the eks-charts repository]
        - helm repo update [--- Update the chart]
        - If your nodes don't have access to Amazon EKS Amazon ECR image repositories, then you need to pull the AWS Load Balancer Controller container image and push it to a repository that your nodes have access to (https://docs.aws.amazon.com/eks/latest/userguide/copy-image-to-repository.html)
            - 602401143452.dkr.ecr.region-code.amazonaws.com/amazon/aws-load-balancer-controller:v2.4.5 (https://docs.aws.amazon.com/eks/latest/userguide/add-ons-images.html) [---> this is the image to be pulled from Amazon EKS Amazon ECR image repositories. Replace 602401143452 and region-code with the values for your AWS Region using the link above]
            - Copy a container image from one repository ( e.g. Amazon EKS Amazon ECR image repositories) to another repository (e.g. your private Amazon ECR your nodes have access to)
                -  aws ecr create-repository --region region-code --repository-name "xxx-xxx-xxx-xxx" [---> this will create a private AmazonnECR Repository in your aws account. Replace region-code with the region you are creating the repository. replace the xxx-xxx-xxx-xxx with any name you wish]
                - 602401143452.dkr.ecr.region-code.amazonaws.com/amazon/aws-load-balancer-controller:v2.4.5 [---> Note the registry/repository[:tag] ) of the image that your nodes need to pull]
                -  aws ecr get-login-password --region region-code | docker login --username AWS --password-stdin 602401143452.dkr.ecr.us-east-1.amazonaws.com [ ---> Get authenticated to the Amazon ECR private registry where the image you intent to pull is stored. Always remember to confirm the image and region-code]
                -  docker pull 602401143452.dkr.ecr.us-east-1.amazonaws.com/amazon/aws-load-balancer-controller:v2.4.5 [ ---> pull the image]
                -  docker tag "dockerimage" "Private AmazonECR Repo (e.g.231596626862.dkr.ecr.us-east-1.amazonaws.com/eks-testing:v2.4.5)" [ ---> Tag the image with your private AmazonECR repository]
                -  aws ecr get-login-password --region region-code | docker login --username AWS --password-stdin "Private AmazonECR Repo (e.g.231596626862.dkr.ecr.us-east-1.amazonaws.com/eks-testing" [---> Authenticate into your own private AmzonECR Registry. Remember to change the region-code]
                -  docker push "the tagged image (e.g. 231596626862.dkr.ecr.us-east-1.amazonaws.com/eks-testing:v2.4.5)" [---> Push the image to your private repo. this is the image you will be using will creating the AWS Load Balancer controller]
        - Install the TargetGroupBinding custom resource definitions
            - kubectl apply -k "github.com/aws/eks-charts/stable/aws-load-balancer-controller/crds?ref=master"
            - If the above command doesn't work, use this work arround
                - Access the github link where the folder is located
                - download the folder into your local machine
                - then run kubectl apply -k "folder_name"
        - Create kubernetes secret that allows you to pull the image from the AmazonECR Registry, since it is a private repository you created
            - kubectl create secret docker-registry "name_of_the_secret" \
                --docker-server="your AmazeonECR Private registry" \
                --docker-username=AWS \
                --docker-password=$(aws ecr get-login-password) \
                --namespace=kube-system
            - e.g. kubectl create secret docker-registry albcred \
                    --docker-server=231596626862.dkr.ecr.us-east-1.amazonaws.com \
                    --docker-username=AWS \
                    --docker-password=$(aws ecr get-login-password) \
                    --namespace=kube-system
        - Make changes to the Helm Chart, where the aws-load-balancer will be installed from ( When installing the chart, specify the registry/repository:tag for the image that you pushed to your repository.)
            - helm show values eks/aws-load-balancer-controller >> alb.yml [---> this will append the content of eks/aws-load-balancer-controller to alb.yml file for easy editing]
            - edit the;
                image:
                  repository: 231596626862.dkr.ecr.us-east-1.amazonaws.com/eks-testing
                  tag: latest
                  pullPolicy: IfNotPresent

                imagePullSecrets:
                  - name: albcred
        - Install the AWS Load Balancer Controller (Remember to pass the alb.yml file)
            - helm install aws-load-balancer-controller eks/aws-load-balancer-controller -n kube-system  -f alb.yml --set clusterName=my-cluster --set serviceAccount.create=false --set serviceAccount.name=aws-load-balancer-controller
            - remember to replace my-cluster with your cluster name
            - you can also pass the region and vpc-id tage (--set region=us-east-1 --set vpcId=vpc-0fce1d14275000a7a), If you're deploying the controller to Amazon EC2 nodes that have restricted access to the Amazon EC2 instance metadata service (IMDS) (https://aws.github.io/aws-eks-best-practices/security/docs/iam/#restrict-access-to-the-instance-profile-assigned-to-the-worker-node)
            - helm upgrade aws-load-balancer-controller eks/aws-load-balancer-controller -n kube-system  -f alb.yml --set clusterName=my-cluster --set serviceAccount.create=false --set serviceAccount.name=aws-load-balancer-controller
        - Verify the controller is installed
            - kubectl get deployment -n kube-system aws-load-balancer-controller

#### To test that the AWS Load Balance Controller is working
    - Deploy a sample game
        - kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/v2.4.5/docs/examples/2048/2048_full.yaml
        - Also you can download the content of the link above, create your own manifest file and deploy
        - But before deployign your manifest file, make below changes (pass the subnets that's associated with your cluster and node)
            -   alb.ingress.kubernetes.io/healthcheck-path: /healthcheck
            -   alb.ingress.kubernetes.io/subnets: subnet-XXXXX, subnet-XXXXX
        - kubectl get ingress/ingress-2048 -n game-2048 [---> check to see if the ingress is deployed and comes with an address]
        - Copy the address and check to see if the app get loaded

#### Troubelshoot for error
+ https://aws.amazon.com/premiumsupport/knowledge-center/eks-ecr-troubleshooting/
+ https://devopscube.com/troubleshoot-kubernetes-pods/

    - kubectl logs -n kube-system deployment.apps/aws-load-balancer-controller
    - kubectl get endpoints -n game-2048
    - kubectl get ingress/2048-ingress -n 2048-game
    - kubectl get event -n game-2048
    - helm repo list
    - helm search repo
    - helm repo remove eks
    - kubectl --namespace game-2048 get services -o wide
    - kubectl get pods --all-namespaces
    - kubectl get all -n game-2048
    - kubectl get pods -n game-2048
    - kubectl get pods --namespace game-2048
    - kubectl delete all  --all -n game-2048
    - helm delete aws-load-balancer-controller -n kube-system





