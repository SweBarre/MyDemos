# CaaSP Demo setup
To get the demo environment up and running you need the ISO images and preferably a working SMT server.
You could use SCC directly, and if you don't have that I will add some comments on how to set one up as a VM in the demo environment


## Prerequisite
All scripts and commands are ment to be run as a user with credentials to create and modify KVM. I'm running this on my lap-top so I've only tried to run the scripts directly on the KVM-host.

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
10.10.10.101 master.suse.lab master
10.10.10.102 worker1.suse.lab worker1
10.10.10.103 worker2.suse.lab worker2
10.10.10.104 worker3.suse.lab worker3
EOF
```
### NTP on KVM-host
TODO: Add instructions on howto enable NTP on KVM-host

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


![archtiecture](https://github.com/SweBarre/MyDemos/blob/master/CaaSP/images/architecture.png)
