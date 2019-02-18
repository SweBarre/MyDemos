# NFS Provisioner

This will create a NFS provisioner in the CaaSP for **testing** purposes
Deployment source @ [nfs-provisioner](https://github.com/kubernetes-incubator/external-storage/tree/master/nfs)

This will create a storage class named *example-nfs*

First configure the Pod Security Policies so that we enable hostpath (disabled by default in CaaSP)
```bash
kubectl create -f psp.yaml
```
create the deployment

```bash
kubectl create -f deployment.yaml
```

Create ClusterRole, ClusterRoleBinding, Role and RoleBinding
```bash
kubectl create -f rbac.yaml 
```

And finally create the storage class
```bash
kubectl create -f class.yaml
```

You could test the storage class by creating a claim
kubectl apply -f claim.yaml
