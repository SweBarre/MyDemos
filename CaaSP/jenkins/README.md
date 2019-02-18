# Install Jenkins in your CaaSP

This requires that you have persistant storage configured, in this example we use the nfs-provisioner with a storage class name : example-nfs

create the namespaces
```bash
kubectl create namespace cdpipeline
kubectl create namespace development
```

copy the storage secret to the new namespaces
```bash
kubectl get secret -o json $(kubectl get secret | awk '{print $1}' | grep nfs-provisioner) | \
  sed 's/"namespace": "default"/"namespace": "cdpipeline"/' | kubectl create -f -

kubectl get secret -o json $(kubectl get secret | awk '{print $1}' | grep nfs-provisioner) | \
  sed 's/"namespace": "default"/"namespace": "development"/' | kubectl create -f -
```


deploy the heml chart with
```bash
helm install stable/jenkins \
  --name jenkins \
  --namespace cdpipeline \
  --set Master.ServiceType=NodePort \
  --set Persistence.StorageClass=example-nfs \
  --set rbac.install=true \
  --set rbac.roleRef=suse:caasp:psp:privileged
```
```bash
kubectl apply -f jenkins-clusterrolebindings.yaml
```

```bash
kubectl apply -f jenkins-admin-binding.yaml
```

When the pod is up and running, retrieve the jenkins credentials with
```bash
$ printf $(kubectl get secret --namespace cdpipeline jenkins -o jsonpath="{.data.jenkins-admin-password}" | base64 --decode);echo
```
