# CaaSP Demo setup
This demo was created to go through the installation process as if it was manually done on bare metal servers, there are other images for CaaSP that are specificly for kvm, openstack, vmware, etc, that makes it even easier to deploy.

To get the demo environment up and running you need the ISO images and preferably a working SMT server.
You could use SCC directly, and if you don't have that I will add some comments on how to set one up as a VM in the demo environment

The final installation will be
![archtiecture](https://github.com/SweBarre/MyDemos/blob/master/CaaSP/images/architecture.png)

## Prerequisite
All scripts and commands are ment to be run as a user with credentials to create and modify KVM. I'm running this on my lap-top so I've only tried to run the scripts directly on the KVM-host.

If you want to override anything defined in the `default.env` you can create a `local.env` file and redefine the variables in `local.env`.

### Network.
The KVM host will act as NTP, DHCP and DNS for the Demo environment.
First edit the caaspnet.xml file to fit your needs, then run the `add_network.sh` script from the same directory as the caaspnet.xml file is located to set up the network.

### edit the /etc/hosts
on the kvm-host you need to add the ip-addresses and hostnames to fit your environment.
```bash
cat << EOF | sudo tee -a /etc/hosts
#CaaSP Demo VM
10.10.10.10 smt.suse.lab smt
10.10.10.100 admin.suse.lab admin
10.10.10.101 master-1.suse.lab master-1
10.10.10.102 worker-1.suse.lab worker-1
10.10.10.103 worker-2.suse.lab worker-2
10.10.10.104 worker-3.suse.lab worker-3
EOF
```
### NTP on KVM-host
Configure NTP client on the kvm host by running
`sudo yast ntp-client`
and select "Now and boot" and make sure you have som servers configured

![yast](https://github.com/SweBarre/MyDemos/blob/master/CaaSP/images/yast-ntp-client.png)

## Install CaaSP
### Administration dashbord (Velum)
Start the installation by first installing the admin server.
```bash
./caasp_deploy.sh admin
```
This will launch the VM and display the VNC virt-viewer.

After some time you will be prompted to select your system settings for the admin server
Choose your language, keyboard layout, root password and specify the URL for the smt (or enter registration code) and select "Administration Node" as systemrole.
Also set the KVM-Host as your NTP Server
![Admin](https://github.com/SweBarre/MyDemos/blob/master/CaaSP/images/admin1.png)

wait for the server to install and be rebooted.
The administration node will then start a bunch of services (containers), this might take a couple of minutes.
Point your favorite browser to https://admin.suse.lab and accept the certificate and go through the initial CaaSP configuration.

First you have to create your "master" administration account, click on "Create Account" and enter email-address and select a password.
![Velum](https://github.com/SweBarre/MyDemos/blob/master/CaaSP/images/admin2.png)

You will be presented with the initial CaaS Platform configuration page
select "Install Tiller" if you want to use helm charts
then click next
![Velum](https://github.com/SweBarre/MyDemos/blob/master/CaaSP/images/admin3.png)

The initial CaaSP configuration is not complete, you can now boot the rest of the cluster node and point and add `autoyast=http://admin.suse.lab/autoyast` as boot parameter and they will autoinstall and register to the admin server (this is already done in the `caasp_deploy.sh` script)
Click next
![Velum](https://github.com/SweBarre/MyDemos/blob/master/CaaSP/images/admin4.png)

We've not yet created any other nodes so the "Pending Nodes" will be empty. When they are installed they will show up as pending nodes.
![Velum](https://github.com/SweBarre/MyDemos/blob/master/CaaSP/images/admin5.png)

### Create cluster nodes
Just run the `caasp_deploy.sh` script with the number of cluster nodes you need (default config for this demo is designed for one master and three workers).
We start with one master and two workers.
```bash
./caasp_deploy.sh master 1 worker 2
```
virt-viewer will launch for every node, the installation will comlete without any user input because we will point the installation to the autoyast created on the administration node.
Eventually when the installation is completed the nodes will pop up in the velum user interface (https://admin.suse.lab)
![Velum](https://github.com/SweBarre/MyDemos/blob/master/CaaSP/images/admin6.png)

Accept the nodes by clicking "Accept All Nodes"
When the nodes are registred and accepted the will pop up as unused nodes.
Select the appropriate roles for the nodes and click Next
![Velum](https://github.com/SweBarre/MyDemos/blob/master/CaaSP/images/admin7.png)

Before you bootstrap the kubernetes cluster you have to confirm the FQDN for the External Kubernetes API and the External Dashboard. In this demo the Kubernetes API FQDN is the same as the only master (master-1.suse.lab) and the dashboard is admin.suse.lab
![Velum](https://github.com/SweBarre/MyDemos/blob/master/CaaSP/images/admin8.png)

click "Bootstrap cluster"

The kubernetes cluster is now beeing bootstrapped, it will take a while to complete.
![Velum](https://github.com/SweBarre/MyDemos/blob/master/CaaSP/images/admin9.png)

When the k8s sluster is bootstrapped you will see all green in the user interface and you can download the kubeconfig by clicking `kubeconfig`
![Velum](https://github.com/SweBarre/MyDemos/blob/master/CaaSP/images/admin10.png)

You will be redirected to the Kubernetes API FQDN (master-1.suse.lab) and you have to accept the certificate and enter your credentials to authenticate
![Velum](https://github.com/SweBarre/MyDemos/blob/master/CaaSP/images/admin11.png)


Download the kubeconfig file and save it to ~/.kube/config
![Velum](https://github.com/SweBarre/MyDemos/blob/master/CaaSP/images/admin12.png)

Click "Home" to return to the velum GUI

You can test the connectivity
```
$ kubectl get nodes -o wide
NAME       STATUS    ROLES     AGE       VERSION   EXTERNAL-IP   OS-IMAGE                 KERNEL-VERSION          CONTAINER-RUNTIME
master-1   Ready     master    18m       v1.9.8    <none>        SUSE CaaS Platform 3.0   4.4.162-94.72-default   docker://17.9.1
worker-1   Ready     <none>    18m       v1.9.8    <none>        SUSE CaaS Platform 3.0   4.4.162-94.72-default   docker://17.9.1
worker-2   Ready     <none>    18m       v1.9.8    <none>        SUSE CaaS Platform 3.0   4.4.162-94.72-default   docker://17.9.1
```

## Expanding cluster
Add a third worker node by executing
```
./caasp_deploy.sh add worker 3
```
virt-viewer will launch and the node will be installed.
When the node has finished installing it will pop up in the velum interface under "Pending Nodes"
![Velum](https://github.com/SweBarre/MyDemos/blob/master/CaaSP/images/admin13.png)

Accept the node and it will soon be flagged added as "Unassigned nodes"
![Velum](https://github.com/SweBarre/MyDemos/blob/master/CaaSP/images/admin14.png)

click on "new" and select the node as worker
![Velum](https://github.com/SweBarre/MyDemos/blob/master/CaaSP/images/admin15.png)

Click "Add nodes" and when the deployment is finished you can varify with kubectl that the node is part of the cluster
```
$ kubectl get nodes -o wide
NAME       STATUS    ROLES     AGE       VERSION   EXTERNAL-IP   OS-IMAGE                 KERNEL-VERSION          CONTAINER-RUNTIME
master-1   Ready     master    50m       v1.9.8    <none>        SUSE CaaS Platform 3.0   4.4.162-94.72-default   docker://17.9.1
worker-1   Ready     <none>    50m       v1.9.8    <none>        SUSE CaaS Platform 3.0   4.4.162-94.72-default   docker://17.9.1
worker-2   Ready     <none>    50m       v1.9.8    <none>        SUSE CaaS Platform 3.0   4.4.162-94.72-default   docker://17.9.1
worker-3   Ready     <none>    5m        v1.9.8    <none>        SUSE CaaS Platform 3.0   4.4.162-94.72-default   docker://17.9.1
```
