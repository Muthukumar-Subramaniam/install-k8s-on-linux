# install-k8s-on-linux
Bash script automated kubeadm based installation of latest version of kubernetes single control plane node and worker nodes on linux ( Red Hat based, Debian based and SUSE based ) for development and testing.

Installs and configures control plane node or worker node with latest stable k8s version available.
Supported distributions : Red Hat based, Debian based, SUSE based).

Also latest versions of below components are installed,  
- Container runtime used : containerd  
- Low-level container runtime : runc ( dependency of containerd )  
- CNI plugin used : calico (default) (or) calico tigera (optional)  
- Storage Driver : csi smb driver

Download the latest release of the script to the linux users account's home directory which is going to manage the k8s cluster.
```
var_latest_version=$(curl -s -L https://api.github.com/repos/Muthukumar-Subramaniam/install-k8s-on-linux/releases/latest | jq -r '.tag_name' 2>>/dev/null | tr -d '[:space:]')
```
```
wget https://github.com/Muthukumar-Subramaniam/install-k8s-on-linux/releases/download/${var_latest_version}/install-k8s-on-linux.sh
```
```
chmod +x install-k8s-on-linux.sh
```
1) To Run this script the user account needs to have sudo access without password ( NOPASSWD ).
2) Running the script as root user is not supported as a best practice.
3) Please don't execute the script with sudo command in front of the script.

## Checking whether the user has sudo access with NOPASSWD:
```        
sudo -l | grep -i NOPASSWD
```
Example : Lets say the username is k8suser1,
> [k8suser1@somelinuxhost ~]$ sudo -l | grep -i NOPASSWD  
>       (ALL) NOPASSWD: ALL  

If there is no output, then the user doesn't have sudo access with NOPASSWD.      

        
If you already have a sudo user but with password, you can run the below command to gain NOPASSWD sudo access.
```           
sudo echo "<your linux user's name> ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/<your linux user's name>
```
```
sudo -l | grep -i NOPASSWD
```
Example : Lets say the username is k8suser2,
> [k8suser2@somelinuxhost ~]$ sudo -l | grep -i NOPASSWD  
> [k8suser2@somelinuxhost ~]$  
> [k8suser2@somelinuxhost ~]$ sudo echo "k8suser2 ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/k8suser2  
> [k8suser2@somelinuxhost ~]$  
> [k8suser2@somelinuxhost ~]$ sudo -l | grep -i NOPASSWD  
>        (ALL) NOPASSWD: ALL  

## Usage: ./install-k8s-on-linux.sh [OPTIONS for control plane node or worker node]

## Control Plane Node Options  :
- --ctrl-plane-node        installs and configures control plane node with latest k8s version.  
- --pod-network-cidr        this option sets the CIDR of your choice for the pod network.  
- --calico-with-tigera        optional - calico with tigera is installed instead of basic calico CNI setup.  

Example Usage : 
```
./install-k8s-on-linux.sh --ctrl-plane-node --pod-network-cidr 10.8.0.0/16
```
(OR)
```
./install-k8s-on-linux.sh --ctrl-plane-node --pod-network-cidr 10.8.0.0/16 --calico-with-tigera
```
Important notes on option --pod-network-cidr :  

1) Only accepts networks that falls within private address space ( RFC 1918 ).  
   ( https://datatracker.ietf.org/doc/html/rfc1918 )  
2) As a best practice, CIDR prefixes /16 to /28 are only allowed.  
3) Please make sure it doen't overlap with any other networks in your infrastructure.  
4) Please choose a CIDR block that is large enough for your environment.  

## Worker Nodes Options :
- --worker-node        installs and configures worker node with latest k8s version.  
- --install-kubectl        optional - install kubectl tool on the worker node.  

Example Usage : 
```
./install-k8s-on-linux.sh --worker-node
```
(OR)
```
./install-k8s-on-linux.sh --worker-node --install-kubectl
```
Note :

> kubectl is not installed on worker nodes as it is unnecessary on worker nodes.  
> ( kubelet and kubeadm is enough for worker node functionality and management )  
> kubectl tool is installed on control plane node where we manage the cluster.  
> Also, it can be installed anywhere providing we have access to the cluster API server.  
