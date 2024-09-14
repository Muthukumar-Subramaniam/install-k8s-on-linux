# Ansible playbook for kubeadm-based [kubernetes](https://kubernetes.io/) cluster installation on Linux  

[Stable Release](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/Muthukumar-Subramaniam/install-k8s-on-linux/main/inst-k8s-ansible/playbook_version.json)

----  

This Ansible playbook automates the installation and configuration of a Kubernetes cluster on Linux, with a single control plane node and multiple worker nodes, using [the most recent stable Kubernetes release](https://github.com/kubernetes/kubernetes/releases/latest).  

----  

#### Suitable Environment : Development & Testing

#### System Requirements : Minimum 2 GB RAM & 2 vCPU

#### Supported Platforms : Baremetal, Virtual Machines, Cloud Instances

#### Supported Linux distributions : 
* RedHat-based ( Fedora, RHEL, Rocky Linux, Almalinux, Oracle Linux ) 
* Debian-based  ( Debian, Ubuntu )
* SUSE-based  ( OpenSUSE, SLES )

#### Also, the latest stable versions of the following components will be installed.  
* Container runtime : containerd  
* Low-level container runtime : runc ( dependency for containerd )  
* CNI plugin used : calico CNI   
* Optionally, you can also install  
  * k8s CSI drivers :  
    * csi-driver-nfs  
    * csi-driver-smb  

#### Please [install Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html) if you haven't already.     
* Create a common Linux user on all nodes to be used for the cluster.   
* Enable passwordless SSH authentication from the Ansible host to all cluster nodes.   
* Ensure that the common user has sudo privileges without a password on all cluster nodes.  

## Workflow:  

### 1) Download the tarball for [the most recent stable release of this Ansible project](https://github.com/Muthukumar-Subramaniam/install-k8s-on-linux/releases/latest).  

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
### 2) Update the host-control-plane file with the necessary hostname.  
   
   <img width="410" alt="Screenshot-host-control-plane-file" src="https://github.com/user-attachments/assets/1d465756-4e88-462f-94cd-5b7c8df36d6e">
  
### 3) Update the host-workers file with the necessary hostnames.  
   
   <img width="372" alt="Screenshot-host-workers-file" src="https://github.com/user-attachments/assets/e0476ec1-4ca3-412d-ba72-5a02bf6e17bf">

### 4) Update the pod-network-cidr file with the desired pod network CIDR.  
   
   <img width="404" alt="Screenshot-pod-network-cidr-file" src="https://github.com/user-attachments/assets/278507ea-aec9-4535-8097-4b1ac4a49101">  
   
   * Only private IP addresses, as defined in [RFC 1918](https://datatracker.ietf.org/doc/html/rfc1918) are allowed.  
   * The deployment is configured to accept CIDR prefixes exclusively within the /16 to /28 range.   
   * Ensure that the selected CIDR prefix does not conflict with any existing networks in your infrastructure.  
   * Choose a CIDR prefix that provides sufficient address space for your cluster.  

### 5) Run the setup.sh script to prepare the environment for the Ansible playbook.  
   ```
   ./setup.sh
   ```
   <img width="479" alt="Screenshot-setup-script-run" src="https://github.com/user-attachments/assets/d90744a2-6308-41b0-834e-25d3db0bf713">

### 6) Run the playbook if the setup.sh script completes successfully.  
   ```
   ansible-playbook inst-k8s-ansible.yaml -u <user-name>
   ```
   Expected Outcome:  

   <img width="701" alt="Screenshot-end-output-of-playbook-run" src="https://github.com/user-attachments/assets/d1124bac-7b54-4972-8db8-f0e34d465da2">
   
### 7) Once the Kubernetes cluster is successfully installed and ready, you can optionally install the following CSI drivers.     
   ```
   ansible-playbook optional-k8s-csi-nfs-driver.yaml -u <user-name> 
   ```
   ```
   ansible-playbook optional-k8s-csi-smb-driver.yaml -u <user-name>
   ```

### Kindly note:  
* This playbook is a useful resource for experimenting with Kubernetes and can be customized to meet your specific requirements.  
* Firewall and SELinux are not configured by this playbook. You may need to disable or adjust their settings to allow proper Kubernetes functionality.  
* The playbook utilizes the GitHub API to fetch the current stable versions of all required software components.  
* Compatible with a wide range of Linux distributions.  
* Your feedback and contributions are invaluable to the success of this project.  
* Please report any bugs, suggest new features, or contribute directly to the codebase.  

### Have lots of fun!
#### Feel free to have a look at [my blog](https://ansiblek8s.blogspot.com).
