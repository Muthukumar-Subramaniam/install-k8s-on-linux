# [Ansible](https://www.ansible.com/) playbook for kubeadm-based [Kubernetes](https://kubernetes.io/) cluster installation on Linux  

----  

This Ansible playbook automates the installation and configuration of a Kubernetes cluster on Linux, with a single control plane node and multiple worker nodes, using [the most recent stable Kubernetes release](https://github.com/kubernetes/kubernetes/releases/latest).  

Suitable Environment: Development & Testing

System Requirements: Minimum 2 GB RAM & 2 vCPU

Supported Platforms: Baremetal, Virtual Machines, Cloud Instances

#### Supported Linux distributions: 
* RedHat-based ( Fedora, RHEL, Rocky Linux, Almalinux, Oracle Linux ) 
* Debian-based  ( Debian, Ubuntu )
* SUSE-based  ( OpenSUSE, SLES )

#### Prerequisites:
* Please [install Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html) on the machine where you plan to run the playbook if you haven’t done so already.
* Prepare the cluster nodes by installing any of the above mentioned supported Linux distributions, even with a minimal installation.
* Please ensure that you have DNS set up that resolves all the involved hosts, or update the host files on all hosts with the necessary entries for each involved host.
* Create a common Linux user on all cluster nodes, which will be used for the cluster installation.
* Enable passwordless SSH authentication from the Ansible host to all cluster nodes using the common user created earlier.  
* Ensure the common user has passwordless sudo privileges on all cluster nodes.
 
#### The main playbook installs and configures the latest stable versions of the following required components.   
* Container orchestrator: [kubernetes](https://github.com/kubernetes/kubernetes)
* Container runtime: [containerd](https://github.com/containerd/containerd)  
* Low-level container runtime: [runc](https://github.com/opencontainers/runc) ( dependency for containerd )  
* CNI plugin: [calico](https://github.com/projectcalico/calico)

#### Optional playbooks are available to install the following components once the cluster is ready.  
* [csi-driver-nfs](https://github.com/kubernetes-csi/csi-driver-nfs)
* [csi-driver-smb](https://github.com/kubernetes-csi/csi-driver-smb)
* [MetalLB](https://github.com/metallb/metallb) LoadBalancer

----

### Step-by-Step Workflow:    

#### Step 1) Copy and execute the below command snippet to extract the tarball for the most recent stable release of this Ansible project.  
   [![stable release](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/Muthukumar-Subramaniam/install-k8s-on-linux/main/inst-k8s-ansible/playbook_version.json)](https://github.com/Muthukumar-Subramaniam/install-k8s-on-linux/releases/latest)
   ```
   var_repo_release="Muthukumar-Subramaniam/install-k8s-on-linux/releases"; var_latest_version=$(curl -skL https://api.github.com/repos/${var_repo_release}/latest | jq -r '.tag_name' 2>/dev/null); curl -sL https://github.com/${var_repo_release}/download/${var_latest_version}/inst-k8s-ansible.tar.gz | tar -xzvf - && cd inst-k8s-ansible
   ```
#### Step 2) Update the host-control-plane file with the necessary hostname.  
   
   <img width="362" alt="Screenshot-host-control-plane-file" src="https://github.com/user-attachments/assets/ff689ceb-554a-438b-83e4-efd0b19e0170">
  
#### Step 3) Update the host-workers file with the necessary hostnames.  
   
   <img width="340" alt="Screenshot-host-workers-file" src="https://github.com/user-attachments/assets/ec9b0598-9502-4ba2-ac52-9254e9093500">

#### Step 4) Update the pod-network-cidr file with the desired pod network CIDR.  
   
   <img width="354" alt="Screenshot-pod-network-cidr-file" src="https://github.com/user-attachments/assets/92aaab26-f9a1-43fe-830f-a56ed19eba0a">
  
   * Only private IP addresses, as defined in [RFC 1918](https://datatracker.ietf.org/doc/html/rfc1918) are allowed.  
   * The deployment is configured to accept CIDR prefixes exclusively within the /16 to /28 range.   
   * Ensure that the selected CIDR prefix does not conflict with any existing networks in your infrastructure.  
   * Choose a CIDR prefix that provides sufficient address space for your cluster.  

#### Step 5) Run the setup.py script to prepare the environment for the Ansible playbook.  
   ```
   ./setup.py
   ```
   <img width="497" alt="Screenshot-setup-script-run" src="https://github.com/user-attachments/assets/40cd5400-457b-4428-89b4-8d5d43690f6c">

#### Step 6) Run the playbook if the setup.py script completes successfully.  
   ```
   ./inst-k8s-ansible.yaml
   ```
   Expected Outcome:  

   <img width="704" alt="Screenshot-end-output-of-playbook-run" src="https://github.com/user-attachments/assets/c550925f-1dc4-4536-b1dc-fdfe230749ca">

### Great work! Your cluster is now ready to use.  
   
#### Optional Step 1) To install CSI NFS Driver for the kubernetes cluster if required.
   ```
   ./optional-k8s-csi-nfs-driver.yaml
   ```
  Expected Outcome:  
  
  <img width="702" alt="Screenshot-csi-driver-nfs" src="https://github.com/user-attachments/assets/40732420-acd2-4a09-94d8-128ac44634ce">  

#### Optional Step 2) To install CSI SMB Driver for the kubernetes cluster if required.  
   ```
   ./optional-k8s-csi-smb-driver.yaml
   ```
   Expected Outcome:  

   <img width="694" alt="Screenshot-csi-driver-smb" src="https://github.com/user-attachments/assets/595d50a9-19d8-474c-97bd-e6ee72c09584">

#### Optional Step 3) To install MetalLB loadbalancer for the kubernetes cluster if required.    
   Note: Please make sure to change the address pool range in the playbook as per your environment and requirement. 

   <img width="634" alt="Screenshot-metallb-ip-pool" src="https://github.com/user-attachments/assets/c59970f3-c28d-41d2-b906-ca891dce0ce1">

   ```
   ./optional-install-metallb.yaml
   ```
   Expected Outcome:  

   <img width="699" alt="Screenshot-metallb" src="https://github.com/user-attachments/assets/ca42347a-9b44-43af-9aa2-229713a11192">

### That's all for now! Your trust and engagement means a lot, and I hope you find the playbook useful.

### Kindly note:  
* This playbook is a useful resource for experimenting with Kubernetes and can be customized to meet your specific requirements.    
* The playbook utilizes the GitHub API to fetch the current stable versions of all required software components.  
* Compatible with a wide range of Linux distributions.  
* Your feedback and contributions are invaluable to the success of this project.  
* Please report any bugs, suggest new features, or contribute directly to the codebase.  

### Have lots of fun!  
