# Install k8s cluster on linux nodes with ansible-playbook
ansible automated kubeadm based installation of latest version of kubernetes single control plane node and worker nodes on linux.  
Installs and configures single control plane node and worker nodes with latest stable k8s version available.  

Suitable Environment : Development & Testing

System Requirement : Minimum 2 GM RAM & 2 vCPU

Platform : Baremetal, Virtual Machines, Cloud Instances

Supported distributions : 
* Red Hat based ( Fedora, RHEL, Rocky Linux, Almalinux, Oracle Linux ) 
* Debian based  ( Debian, Ubuntu )
* SUSE based  ( OpenSUSE, SLES )

Also latest versions of below components will be installed,  
* Container runtime used : containerd  
* Low-level container runtime : runc ( dependency of containerd )  
* CNI plugin used : calico CNI   
* Optionally you can also install,  
  * k8s CSI drivers :
    * csi-driver-nfs  
    * csi-driver-smb


If you don't have a machine with ansible already installed, please do install it.  
https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html  

* Create a common user in all the nodes to be used for the cluster.  
* Enable passwordless authentication from the ansible host to all the cluster nodes to be.  
* Also make sure, sudo access with NOPASSWD is enabled for the user in all the nodes.  
* Do ansible ping test from ansible host to all the all the cluster nodes to be.  

Download the tarball of latest release containing ansible template and configs to the linux user account's home directory.

```
var_latest_version=$(curl -skL https://api.github.com/repos/Muthukumar-Subramaniam/install-k8s-on-linux/releases/latest | jq -r '.tag_name' 2>>/dev/null | tr -d '[:space:]')
```
```
wget https://github.com/Muthukumar-Subramaniam/install-k8s-on-linux/releases/download/${var_latest_version}/inst-k8s-ansible.tar.gz
```
```
tar -xzvf inst-k8s-ansible.tar.gz
```
```
cd inst-k8s-ansible
```
1) Change the hostnames of k8s cluster nodes in the k8s-cluster-inventory file as per your setup.   
2) Change the var_k8s_pod_network_cidr variable value in k8s-cluster-inventory as per your requirement.  
   * Currently the value of var_k8s_pod_network_cidr is set to 10.8.0.0/16    
   * Ensure that the CIDR block you choose does not overlap with any of your existing network infra    
3) Please do not change the group names as it is utilized by the template.    
4) Change the ansible user name in ansible.cfg as per your setup.   

That's it, you are good to go!
```
ansible-playbook inst-k8s-ansible.yaml
```

After the cluster is installed and Ready, if required, you can install the below k8s CSI drivers.   
```
ansible-playbook optional-k8s-csi-nfs-driver.yaml 
```
```
ansible-playbook optional-k8s-csi-smb-driver.yaml
```

Sample Execution Result of ansible-playbook inst-k8s-ansible.yaml :    

![sample-output-execution-results](https://github.com/user-attachments/assets/a4a50841-4407-4c21-943c-0828dce76225)



kind note:  
* The template can be utilized for testing and learning purpose, tailor it as per your need if required.
* Firewall and Selinux are not managed by the template, either disable it or configure it as per your requirement.
* The template uses github API to fetch latest stable release of all software components.
* There is a dependency issue in SUSE, work around is applied within the template.
  ( To be fixed in upcoming patch release v1.31.1 of k8s, Ref: https://github.com/kubernetes/release/issues/3711 ) 
* It is well tested on different linux distros.
* Please feel free to provide your suggestions and bug reports if any.

> Have lots of fun!
