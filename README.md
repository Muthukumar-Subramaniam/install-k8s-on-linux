# Install kubernetes cluster on linux nodes with ansible playbook
ansible playbook for kubeadm based installation of latest version of kubernetes single control plane node and worker nodes on linux.  
Installs and configures single control plane node and worker nodes with latest stable kubernetes version available.  

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

Workflow:  

1) Download the tarball of latest release of this ansible project to the linux user account's home directory.

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
2) Update host-control-plane file with the required hostname
   
   <img width="410" alt="Screenshot-host-control-plane-file" src="https://github.com/user-attachments/assets/1d465756-4e88-462f-94cd-5b7c8df36d6e">
  
4) Update host-workers file with the required hostnames
   
   <img width="372" alt="Screenshot-host-workers-file" src="https://github.com/user-attachments/assets/e0476ec1-4ca3-412d-ba72-5a02bf6e17bf">

6) Update pod-network-cidr file with pod network CIDR.
   
   <img width="404" alt="Screenshot-pod-network-cidr-file" src="https://github.com/user-attachments/assets/278507ea-aec9-4535-8097-4b1ac4a49101">  
   
   * Only networks that falls within private address space ( RFC 1918 ) are accepted.  
     * ( https://datatracker.ietf.org/doc/html/rfc1918 )  
   * As a best practice, CIDR prefixes /16 to /28 are only allowed.  
   * Please make sure it doesn't overlap with any other existing networks in your infrastructure.  
   * Please choose a CIDR block that is large enough for your environment.

 

8) Run the setup.sh script to setup the provided environment for ansible play.
   ```
   ./setup.sh
   ```
   <img width="479" alt="Screenshot-setup-script-run" src="https://github.com/user-attachments/assets/d90744a2-6308-41b0-834e-25d3db0bf713">

9) Run the playbook if all goes well with above setup.sh script as shown above
   ```
   ansible-playbook inst-k8s-ansible.yaml -u <user-name>
   ```
   Sample End Result:

   <img width="698" alt="Screenshot-end-output-of-playbook-run" src="https://github.com/user-attachments/assets/105788d3-773f-4adc-8a8b-30a6165afbd5">

   
7) After the cluster is installed and Ready, if required, you can install the below k8s CSI drivers.   
   ```
   ansible-playbook optional-k8s-csi-nfs-driver.yaml -u <user-name> 
   ```
   ```
   ansible-playbook optional-k8s-csi-smb-driver.yaml -u <user-name>
   ```

kind note:  
* The template can be utilized for testing and learning purpose, tailor it as per your need if required.
* Firewall and Selinux are not managed by the template, either disable it or configure it as per your requirement.
* The template uses github API to fetch latest stable release of all software components.
* There is a dependency issue in SUSE, work around is applied within the template.
  ( To be fixed in upcoming patch release v1.31.1 of k8s, Ref: https://github.com/kubernetes/release/issues/3711 ) 
* Well tested on various linux distributions.
* Your contributions help us improve this project. We welcome bug reports, feature requests, and code contributions

> Have lots of fun!
