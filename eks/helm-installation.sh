#Installing Helm
#!/bin/bash
curl -fsSL -o get_helm.sh https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3
sudo chmod 700 get_helm.sh
./get_helm.sh

#Installing nginx ingress controller
$ helm repo add nginx-stable https://helm.nginx.com/stable
$ helm repo update

#Installing Prometheus using Helm
sudo kubectl create namespace prometheus
sudo helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
sudo helm repo update
sudo helm upgrade -i prometheus prometheus-community/prometheus –namespace prometheus
#kubectl get pods -n Prometheus

#Installing Grafana using Helm
sudo kubectl create namespace grafana
sudo helm repo add grafana https://grafana.github.io/helm-charts
sudo helm repo update
helm install grafana grafana/grafana  –namespace grafana   –set persistence.enabled=true  –set adminPassword=’xxxx’ –set datasources.”datasources\.yaml”.apiVersion=1   –set datasources.”datasources\.yaml”.datasources[0].name=Prometheus  –set datasources.”datasources\.yaml”.datasources[0].type=prometheus    –set datasources.”datasources\.yaml”.datasources[0].url=http://prometheus-server.prometheus.svc.cluster.local     –set datasources.”datasources\.yaml”.datasources[0].access=proxy     –set datasources.”datasources\.yaml”.datasources[0].isDefault=true
#kubectl get all -n grafana
#adminPassword

#prometheus and Grafana in same namespace
helm repo add stable "https://charts.helm.sh/stable"
kubectl create namespace monitoring
helm show values stable/prometheus >> prometheus.values.yml
helm install -f prometheus.values.yml prometheus stable/prometheus -n monitoring
helm inspect values stable/grafana >> grafana.values.yml  ##update service-type
helm install -f grafana.values.yml grafana stable/grafana -n monitoring