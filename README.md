# [Ansible](https://www.ansible.com/) playbook for kubeadm-based [Kubernetes](https://kubernetes.io/) cluster installation on Linux  

----  

This Ansible playbook automates the installation and configuration of a Kubernetes cluster on Linux, supporting both single control plane and HA control plane setups, using the [latest stable Kubernetes release](https://github.com/kubernetes/kubernetes/releases/latest).  

While Kubespray provides extensive features and customization options, this playbook remains lightweight and simple, making it an ideal choice for quickly setting up a development or testing Kubernetes environment on Linux.


**Suitable Environment:** Development & Testing

**System Requirements:** Minimum 2 GB RAM & 2 vCPU

**Supported Platforms:** Baremetal, Virtual Machines, Cloud Instances

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
* For HA cluster setups, ensure that the control plane endpoint is configured via a load balancer such as NGINX, HAProxy, or any load balancer of your choice.
 
#### The main playbook installs and configures the latest stable versions of the following required components.   
* Container orchestrator: [kubernetes](https://github.com/kubernetes/kubernetes)
* Container runtime: [containerd](https://github.com/containerd/containerd)  
* Low-level container runtime: [runc](https://github.com/opencontainers/runc) ( dependency for containerd )  
* CNI plugin ( user selectable during setup ):
  * [Calico](https://github.com/projectcalico/calico) — stable, widely adopted CNI with BGP/VXLAN/WireGuard support
  * [Cilium](https://github.com/cilium/cilium) — eBPF-based CNI with kube-proxy replacement and advanced observability

#### Optional playbooks are available to install the following components once the cluster is ready.  
* [csi-driver-nfs](https://github.com/kubernetes-csi/csi-driver-nfs)
* [csi-driver-smb](https://github.com/kubernetes-csi/csi-driver-smb)
* [MetalLB](https://github.com/metallb/metallb) LoadBalancer
* [Cilium Hubble](https://github.com/cilium/hubble) Observability ( available when Cilium CNI is selected )

----

### Step-by-Step Workflow:    

#### Step 1) Copy and execute the below command snippet to extract the tarball for the most recent stable release of this Ansible project.  
   [![stable release](https://img.shields.io/endpoint?url=https://raw.githubusercontent.com/Muthukumar-Subramaniam/install-k8s-on-linux/main/playbook_version.json)](https://github.com/Muthukumar-Subramaniam/install-k8s-on-linux/releases/latest)
   ```
   curl -sSL https://github.com/Muthukumar-Subramaniam/install-k8s-on-linux/releases/latest/download/inst-k8s-ansible.tar.gz | tar -xzvf - && cd inst-k8s-ansible
   ```
#### Step 2) Update the host-control-plane file with the necessary hostnames.  

Use a single control plane node for a single control plane setup. For HA cluster setups, ensure a minimum of 3 control plane nodes, and always use an odd number of nodes.

##### Single Control Plane Setup

   ```text
   [JARVIS](⊛)[inst-k8s-ansible]▶ cat host-control-plane
   test-k8s-cp1.musubram.internal
   [JARVIS](⊛)[inst-k8s-ansible]▶
   ```

##### HA Control Plane Setup

   ```text
   [JARVIS](⊛)[inst-k8s-ansible]▶ cat host-control-plane
   test-k8s-cp1.musubram.internal
   test-k8s-cp2.musubram.internal
   test-k8s-cp3.musubram.internal
   [JARVIS](⊛)[inst-k8s-ansible]▶
   ```

##### Additional Step for HA Control Plane Setup  

* Update the file `control-plane-endpoint` with the endpoint behind the load balancer that has all the control planes in the backend pool.  

* Port configuration:  
  If only `<FQDN of control-plane-endpoint>` is provided, the default port `6443` will be used.  
  Alternatively, provide a specific port as `<FQDN of control-plane-endpoint>:<port-number>`.   

   ```text
   [JARVIS](⊛)[inst-k8s-ansible]▶ cat control-plane-endpoint
   test-k8s-cp.musubram.internal
   [JARVIS](⊛)[inst-k8s-ansible]▶
   ```

   ( Or )

   ```text
   [JARVIS](⊛)[inst-k8s-ansible]▶ cat control-plane-endpoint
   test-k8s-cp.musubram.internal:6443
   [JARVIS](⊛)[inst-k8s-ansible]▶
   ```

#### Step 3) Update the host-workers file with the necessary hostnames.  
   
   ```text
   [JARVIS](⊛)[inst-k8s-ansible]▶ cat host-workers
   test-k8s-w1.musubram.internal
   test-k8s-w2.musubram.internal
   test-k8s-w3.musubram.internal
   test-k8s-w4.musubram.internal
   [JARVIS](⊛)[inst-k8s-ansible]▶
   ```

#### Step 4) Update the pod-network-cidr file with the desired pod network CIDR.  
   
   ```text
   [JARVIS](⊛)[inst-k8s-ansible]▶ cat pod-network-cidr
   10.8.0.0/16
   [JARVIS](⊛)[inst-k8s-ansible]▶
   ```
  
   * Only private IP addresses, as defined in [RFC 1918](https://datatracker.ietf.org/doc/html/rfc1918) are allowed.  
   * The deployment is configured to accept CIDR prefixes exclusively within the /16 to /28 range.   
   * Ensure that the selected CIDR prefix does not conflict with any existing networks in your infrastructure.  
   * Choose a CIDR prefix that provides sufficient address space for your cluster.  

#### Step 5) Run the setup.py script to prepare the environment for the Ansible playbook.  
   The setup script validates all configuration files, prompts you to select a CNI plugin (Calico or Cilium), and prepares the inventory.
   ```
   ./setup.py
   ```
   ```text
   [JARVIS](⊛)[inst-k8s-ansible]▶ ./setup.py
   Check the required files . . . [done]
   HA Cluster Setup is not detected!
   Checking If Single Control Plane Setup is applicable  . . .[done]
   Validate the pod network CIDR . . .[done]

   [CNI Plugin Selection]
   Select the CNI plugin to install:
     1) Calico
     2) Cilium
   Enter your choice (1 or 2): 1
   CNI plugin selected: calico

   [OS Upgrade Option]
   Do you want to upgrade the OS packages on all nodes before installing Kubernetes?
     (This will run a full system upgrade and reboot if changes are applied)
   Upgrade OS packages? (y/N):
   OS upgrade: false
   [done]
   Updating the playbook for Single Control Plan Setup . . . [done]
   Updating pod network CIDR as 10.8.0.0/16 . . . [done]
   Updating CNI plugin selection as calico . . . [done]
   Updating OS upgrade setting as false . . . [done]
   Updating all the nodes in ansible inventory . . . [done]

   [User to manage the k8s cluster]
   Enter the remote username (ansible_user): musubram

   Run ansible ping test for control plane nodes . . .
   test-k8s-cp1.musubram.internal | SUCCESS => {
       "ansible_facts": {
           "discovered_interpreter_python": "/usr/bin/python3"
       },
       "changed": false,
       "ping": "pong"
   }

   Run ansible ping test for worker nodes . . .
   test-k8s-w1.musubram.internal | SUCCESS => {
       "ansible_facts": {
           "discovered_interpreter_python": "/usr/bin/python3"
       },
       "changed": false,
       "ping": "pong"
   }
   test-k8s-w2.musubram.internal | SUCCESS => {
       "ansible_facts": {
           "discovered_interpreter_python": "/usr/bin/python3"
       },
       "changed": false,
       "ping": "pong"
   }
   test-k8s-w3.musubram.internal | SUCCESS => {
       "ansible_facts": {
           "discovered_interpreter_python": "/usr/bin/python3"
       },
       "changed": false,
       "ping": "pong"
   }
   test-k8s-w4.musubram.internal | SUCCESS => {
       "ansible_facts": {
           "discovered_interpreter_python": "/usr/bin/python3"
       },
       "changed": false,
       "ping": "pong"
   }
   Update ansible.cfg with remote user . . . [done]

   All set, you are good to go!

   Cluster Setup Type : Single Control Plane

   You can now run the playbook whenever you are ready!
   ./inst-k8s-ansible.yaml

   [JARVIS](⊛)[inst-k8s-ansible]▶
   ```

#### Step 6) Run the playbook if the setup.py script completes successfully.  
   ```
   ./inst-k8s-ansible.yaml
   ```

   **Optional: Pin specific component versions**  
   By default, the playbook installs the latest stable versions. To pin specific versions, pass them as extra variables:
   ```
   ./inst-k8s-ansible.yaml -e "runc_version=v1.4.3" -e "containerd_version=v1.7.28" -e "k8s_version=v1.34.10" -e "calico_version=v3.32.1"
   ```
   Available version overrides: `runc_version`, `containerd_version`, `k8s_version`, `calico_version`, `cilium_cli_version`  
   Any variable not specified will default to the latest stable release.  
   All user-specified versions are validated against GitHub before installation.

   Expected Outcome:  

   ```text
   TASK [check_cluster_ready_status : Manage this cluster from test-k8s-cp1.musubram.internal with user musubram]

   ok: [test-k8s-cp1.musubram.internal] => {
       "msg": [
           "NAME                             STATUS   ROLES           AGE   VERSION",
           "test-k8s-cp1.musubram.internal   Ready    control-plane   99s   v1.36.3",
           "test-k8s-w1.musubram.internal    Ready    worker          66s   v1.36.3",
           "test-k8s-w2.musubram.internal    Ready    worker          66s   v1.36.3",
           "test-k8s-w3.musubram.internal    Ready    worker          66s   v1.36.3",
           "test-k8s-w4.musubram.internal    Ready    worker          66s   v1.36.3"
       ]
   }

   PLAY RECAP *********************************************************************
   test-k8s-cp1.musubram.internal : ok=112  changed=33   unreachable=0    failed=0    skipped=49   rescued=0    ignored=0
   test-k8s-w1.musubram.internal  : ok=54   changed=23   unreachable=0    failed=0    skipped=49   rescued=0    ignored=0
   test-k8s-w2.musubram.internal  : ok=54   changed=23   unreachable=0    failed=0    skipped=49   rescued=0    ignored=0
   test-k8s-w3.musubram.internal  : ok=54   changed=23   unreachable=0    failed=0    skipped=49   rescued=0    ignored=0
   test-k8s-w4.musubram.internal  : ok=54   changed=23   unreachable=0    failed=0    skipped=49   rescued=0    ignored=0
   ```

   For full playbook output, see [docs/example-playbook-output.txt](docs/example-playbook-output.txt)

### Great work! Your cluster is now ready to use.  
   
#### Optional Step 1) To install CSI NFS Driver for the Kubernetes cluster if required.
   ```
   ./optional-k8s-csi-nfs-driver.yaml
   ```
   Expected Outcome:  

   ```text
   TASK [install_k8s_csi_nfs_driver : Successfully deployed csi-nfs-driver pods for k8s cluster]

   ok: [test-k8s-cp1.musubram.internal] => {
       "msg": [
           "csi-nfs-controller-65b4f9877-bvhch   5/5   Running   1 (4s ago)   42s",
           "csi-nfs-node-8bxxb                   3/3   Running   0            41s",
           "csi-nfs-node-fbdck                   3/3   Running   0            41s",
           "csi-nfs-node-l7fxj                   3/3   Running   0            41s",
           "csi-nfs-node-qtlts                   3/3   Running   0            41s",
           "csi-nfs-node-s4x8f                   3/3   Running   0            41s"
       ]
   }

   PLAY RECAP *******************************************************************************************
   test-k8s-cp1.musubram.internal : ok=14   changed=2    unreachable=0    failed=0    skipped=2    rescued=0    ignored=0
   ```

   For full output, see [docs/example-optional-csi-nfs-driver-output.txt](docs/example-optional-csi-nfs-driver-output.txt)  

#### Optional Step 2) To install CSI SMB Driver for the Kubernetes cluster if required.  
   ```
   ./optional-k8s-csi-smb-driver.yaml
   ```
   Expected Outcome:  

   ```text
   TASK [install_k8s_csi_smb_driver : Successfully deployed csi-smb-driver pods for k8s cluster]

   ok: [test-k8s-cp1.musubram.internal] => {
       "msg": [
           "csi-smb-controller-79bf65f474-lzfwf   4/4   Running   0     24s",
           "csi-smb-node-dtqrb                    3/3   Running   0     24s",
           "csi-smb-node-gzl44                    3/3   Running   0     24s",
           "csi-smb-node-l6br6                    3/3   Running   0     24s",
           "csi-smb-node-ncgz5                    3/3   Running   0     24s",
           "csi-smb-node-r2z9d                    3/3   Running   0     24s"
       ]
   }

   PLAY RECAP *******************************************************************************************
   test-k8s-cp1.musubram.internal : ok=14   changed=2    unreachable=0    failed=0    skipped=2    rescued=0    ignored=0
   ```

   For full output, see [docs/example-optional-csi-smb-driver-output.txt](docs/example-optional-csi-smb-driver-output.txt)

#### Optional Step 3) To install MetalLB LoadBalancer for the Kubernetes cluster if required.    
   Note: Please make sure to change the address pool range in the playbook as per your environment and requirement. 

   ```yaml
   # optional-install-metallb.yaml
   vars:
     k8s_metallb_ip_pool_range: "10.28.31.101-10.28.31.155" # Change it as per your environment
   ```

   ```
   ./optional-install-metallb.yaml
   ```
   Expected Outcome:  

   ```text
   TASK [install_and_configure_metallb : Notify MetalLB IPAddressPool details]

   ok: [test-k8s-cp1.musubram.internal] => {
       "msg": [
           "NAME                  AUTO ASSIGN   AVOID BUGGY IPS   ADDRESSES",
           "k8s-metallb-ip-pool   true          false             [\"10.28.31.101-10.28.31.155\"]"
       ]
   }

   TASK [install_and_configure_metallb : Successfully deployed MetalLB LoadBalancer for the k8s cluster]

   ok: [test-k8s-cp1.musubram.internal] => {
       "msg": [
           "NAME                          READY   STATUS    RESTARTS   AGE",
           "controller-545b968bd8-jsbxl   1/1     Running   0          39s",
           "speaker-7kftj                 1/1     Running   0          39s",
           "speaker-7m72v                 1/1     Running   0          39s",
           "speaker-fm4jx                 1/1     Running   0          39s",
           "speaker-pxkkm                 1/1     Running   0          39s",
           "speaker-v4sts                 1/1     Running   0          39s"
       ]
   }

   PLAY RECAP *******************************************************************************************
   test-k8s-cp1.musubram.internal : ok=16   changed=3    unreachable=0    failed=0    skipped=2    rescued=0    ignored=0
   ```

   For full output, see [docs/example-optional-install-metallb-output.txt](docs/example-optional-install-metallb-output.txt)

#### Optional Step 4) To enable Cilium Hubble observability for the Kubernetes cluster if required ( only applicable when Cilium CNI is selected ).
   ```
   ./optional-install-cilium-hubble.yaml
   ```

### That's all for now! Your trust and engagement mean a lot, and we hope you find the playbook useful.

### Kindly note:  
* This playbook is a useful resource for experimenting with Kubernetes and can be customized to meet your specific requirements.    
* The playbook utilizes the GitHub API to fetch the current stable versions of all required software components.  
* Compatible with a wide range of Linux distributions.  
* Your feedback and contributions are invaluable to the success of this project.  
* Please report any bugs, suggest new features, or contribute directly to the codebase.  

### Have lots of fun!  
