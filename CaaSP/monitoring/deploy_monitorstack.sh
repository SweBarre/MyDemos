cd $(dirname "${BASH_SOURCE[0]}")
clear
echo "Create the monitoring namespace"
echo "cmd: kubectl create namespace monitoring"
kubectl create namespace monitoring
read -p "Press any key to continue... " -n1 -s
clear
echo "Create PV and PVC"
echo "cmd: kubectl apply -f pv-pvclaim.yaml"
less pv-pvclaim.yaml
kubectl apply -f pv-pvclaim.yaml
read -p "Press any key to continue... " -n1 -s
clear


echo "Add the entries to the one of your workernodes in the DNS-server"
cat << EOF
monitoring.example.com                      IN  A       10.10.10.102
prometheus.example.com                      IN  CNAME   monitoring.example.com
prometheus-alertmanager.example.com         IN  CNAME   monitoring.example.com
grafana.example.com                         IN  CNAME   monitoring.example.com

or as in my example, add the following to the /etc/hosts
10.10.10.102 prometheus.example.com prometheus-alertmanager.example.com grafana.example.com

echo "10.10.10.102 prometheus.example.com prometheus-alertmanager.example.com grafana.example.com" | sudo tee -a /etc/hosts
EOF
read -p "Press any key to continue... " -n1 -s
clear

echo "Deploy the Nginx ingress controller with helm.."
echo "----------------------------------------------"
cat nginx-ingress-config-values.yaml
echo "----------------------------------------------"
echo "cmd: helm install --name nginx-ingress stable/nginx-ingress \\
          --namespace monitoring \\
          --values nginx-ingress-config-values.yaml"
read -p "Press any key to continue... " -n1 -s
helm install --name nginx-ingress stable/nginx-ingress \
--namespace monitoring \
--values nginx-ingress-config-values.yaml
read -p "Press any key to continue... " -n1 -s

watch kubectl -n monitoring get pods
clear

echo "We will be using self-signed certificates in this demo"
echo "     !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
echo "     !!                              !!"
echo "     !! DO NOT DO THIS IN PRODUCTION !!"
echo "     !!                              !!"
echo "     !!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!"
echo ""
echo "cat openssl.conf"
cat openssl.conf
read -p "Press any key to continue... " -n1 -s
clear
echo "cmd: openssl req -x509 -nodes -days 365 -newkey rsa:4096 \\
              -keyout ./monitoring.key -out ./monitoring.crt \\
              -config ./openssl.conf -extensions 'v3_req'"
openssl req -x509 -nodes -days 365 -newkey rsa:4096 \
  -keyout ./monitoring.key -out ./monitoring.crt \
  -config ./openssl.conf -extensions 'v3_req'
echo ""
echo "Add the certificates to Kubernetes"
echo "cmd: kubectl create -n monitoring secret tls monitoring-tls  \\
          --key  ./monitoring.key \\
          --cert ./monitoring.crt"

kubectl create -n monitoring secret tls monitoring-tls  \
  --key  ./monitoring.key \
  --cert ./monitoring.crt

echo ""	  
read -p "Press any key to continue... " -n1 -s

clear
echo "    ###################################"
echo "    #                                 #"
echo "    #          Prometheus             #"
echo "    #                                 #"
echo "    ###################################"
echo ""
echo "make sure you have htpasswd installed (package apache2-utils)"
echo "cmd: sudo zypper in apache2-utils"
echo ""
echo "create the password admin password for prometheus"
echo "cmd: htpasswd -c auth admin"
read -p "Press any key to continue... " -n1 -s
echo ""
echo "create the secret in Kubernetes"
echo "cmd: kubectl create secret generic -n monitoring prometheus-basic-auth --from-file=auth"
kubectl create secret generic -n monitoring prometheus-basic-auth --from-file=auth
read -p "Press any key to continue... " -n1 -s

echo ""
echo "create the prometheus configuration"
read -p "Press any key to continue... " -n1 -s
less prometheus-config-values.yaml
echo ""
echo "Deploy the configuration with helm"
echo "cmd: helm install --name prometheus stable/prometheus \\
             --namespace monitoring \\
             --values prometheus-config-values.yaml"
helm install --name prometheus stable/prometheus \
  --namespace monitoring \
  --values prometheus-config-values.yaml
read -p "Press any key to continue... " -n1 -s
watch kubectl -n monitoring get pods
clear

echo "    ###################################"
echo "    #                                 #"
echo "    #          Grafana                #"
echo "    #                                 #"
echo "    ###################################"
echo ""
echo "Configure the provisioning"
echo ""
cat grafana-datasources.yaml
read -p "Press any key to continue... " -n1 -s
echo ""
echo "Create the ConfigMap in Kubernetes"
echo "cmd: kubectl create -f grafana-datasources.yaml"
kubectl create -f grafana-datasources.yaml
read -p "Press any key to continue... " -n1 -s
echo ""
echo "Configure the grafana config"
read -p "Press any key to continue... " -n1 -s
less grafana-config-values.yaml 
echo "Deploy grafana"
echo "cmd: helm install --name grafana stable/grafana \\
               --namespace monitoring \\
               --values grafana-config-values.yaml"
helm install --name grafana stable/grafana \
  --namespace monitoring \
  --values grafana-config-values.yaml
read -p "Press any key to continue... " -n1 -s
watch kubectl -n monitoring get pods
echo ""
echo "Add a dashboard to grafana"
echo "cmd: kubectl apply -f grafana-dashboards-caasp-cluster.yaml"
kubectl apply -f grafana-dashboards-caasp-cluster.yaml

