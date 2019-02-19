# Monitoring stack with Prometheus and Grafana

this requires persistant storage, you could use the [nfs-provisioner](https://github.com/SweBarre/MyDemos/tree/master/CaaSP/nfs) with a storage class name : example-nfs

You also need the helm client binary installed on your client

## Prereq
Add the entries to the one of your workernodes in your clients host file
```
echo "10.10.10.102 prometheus.example.com prometheus-alertmanager.example.com grafana.example.com" | sudo tee -a /etc/hosts
```

Create the monitoring namespace
```bash
kubectl create namespace monitoring
```
copy the storage secret to the new namespaces
```bash
kubectl get secret -o json $(kubectl get secret | awk '{print $1}' | grep nfs-provisioner) | \
  sed 's/"namespace": "default"/"namespace": "monitoring"/' | kubectl create -f -
```

We will be using self signed certificates for prometheus and grafana, we need to create that (the same certificate will be used for all three URLs)
```bash
openssl req -x509 -nodes -days 365 -newkey rsa:4096 \
  -keyout ./monitoring.key -out ./monitoring.crt \
  -config ./openssl.conf -extensions 'v3_req'
```

Add the certificate as a secret to kubernetes
```bash
kubectl create -n monitoring secret tls monitoring-tls  \
  --key  ./monitoring.key \
  --cert ./monitoring.crt
```

We will be using basic authentication for Prometheus so we need to install the htpasswd binary on your client inorder to create the auth file
```bash
sudo zypper in apache2-utils
```

## nginx-ingress
we will be using the nginx-ingress controller for our monitoring stack, so lets install that
```bash
helm install --name nginx-ingress stable/nginx-ingress \
          --namespace monitoring \
          --values nginx-ingress-config-values.yaml
```

## Prometheus
create the authentication file for prometheus
```bash
htpasswd -c auth admin linux
```

Create a kubernets secret from that file
```bash
kubectl create secret generic -n monitoring prometheus-basic-auth --from-file=auth
```

Deploy prometheus with helm, it will deploy both prometheus and prometheus-alert, and node-exporter pods
```
helm install --name prometheus stable/prometheus \
  --namespace monitoring \
  --values prometheus-config-values.yaml
```

## Grafana
first of we create the datasource to be used for grafana
```bash
kubectl create -f grafana-datasources.yaml
```

deploy the Grafana
```bash
helm install --name grafana stable/grafana \
  --namespace monitoring \
  --values grafana-config-values.yaml
```

and a grafana dashboard as a ConfigMap
```bash
kubectl apply -f grafana-dashboards-caasp-cluster.yaml
```

