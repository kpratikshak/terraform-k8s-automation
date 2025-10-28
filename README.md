
## Petstore K8s Deployment via Jenkins & Ansible

This workflow provisions all infrastructure on AWS using Terraform, then uses a Jenkins pipeline to build,
test, scan, and deploy a Petstore application to a Kubernetes cluster using Ansible.


# Phase 1: Provision Infrastructure (Terraform)

Clone this Repository: Get all the Terraform (.tf), Ansible (.yml), and script (.sh) files.

Initialize Terraform:

terraform init


Deploy Infrastructure:

terraform apply -auto-approve

Get Outputs: After the apply finishes, Terraform will output:

private_key_path: The path to your new SSH key (e.g., petstore-key.pem).

jenkins_server_ip: Public IP for Jenkins.

ansible_server_ip: Public IP for the Ansible server.

k8s_master_ip: Public IP for the K8s master.

k8s_worker_ip: Public IP for the K8s worker.

petstore_app_dns: The final URL for your application.

Note: The petstore-key.pem file is now on your local machine.


#  Phase 2: Manual K8s Cluster Setup

SSH to K8s Master:

ssh -i petstore-key.pem ubuntu@[k8s_master_ip]


Initialize Cluster (on Master):

# Use the master's PRIVATE IP
sudo kubeadm init --pod-network-cidr=10.244.0.0/16 --apiserver-advertise-address=$(hostname -i)

# Configure kubectl for ubuntu user
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Apply Flannel CNI (networking)
kubectl apply -f [https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml](https://raw.githubusercontent.com/flannel-io/flannel/master/Documentation/kube-flannel.yml)


Get Join Command (on Master):

kubeadm token create --print-join-command


SSH to K8s Worker (in a new terminal):

ssh -i petstore-key.pem ubuntu@<k8s_worker_ip>


Join Worker to Cluster (on Worker):

Paste and run the sudo kubeadm join ... command you copied from the master.

Verify Cluster (on Master):

kubectl get nodes


You should see both the master and worker nodes in a Ready state after a minute.

Phase 3: Configure Ansible Server

SCP Key & Inventory to Ansible Server: From your local machine, send the private key and the inventory file (which Terraform created in the ansible/ folder) to the Ansible server.

# Create the inventory file from the template
terraform output jenkins_server_ip | xargs -I {} sed "s/\${jenkins_ip}/{}/" ansible/inventory.ini.tpl > ansible/inventory.ini
terraform output ansible_server_ip | xargs -I {} sed -i "s/\${ansible_ip}/{}/" ansible/inventory.ini
terraform output k8s_master_ip | xargs -I {} sed -i "s/\${k8s_master_ip}/{}/" ansible/inventory.ini
terraform output k8s_worker_ip | xargs -I {} sed -i "s/\${k8s_worker_ip}/{}/" ansible/inventory.ini

# SCP the files
scp -i petstore-key.pem petstore-key.pem ubuntu@<ansible_server_ip>:/home/ubuntu/petstore-key.pem
scp -i petstore-key.pem ansible/inventory.ini ubuntu@<ansible_server_ip>:/home/ubuntu/inventory.ini


SSH to Ansible Server:

ssh -i petstore-key.pem ubuntu@<ansible_server_ip>


Set Key Permissions (on Ansible Server):

chmod 600 /home/ubuntu/petstore-key.pem

# Clone your Petstore repo here so the playbooks exist
git clone [https://github.com/lastoyster/petstore-repo.git] /home/ubuntu/petstore-repo
# Copy the inventory and playbook into the repo dir (or adjust paths in Jenkinsfile)
cp /home/ubuntu/inventory.ini /home/ubuntu/petstore-repo/inventory.ini
cp /home/ubuntu/petstore-repo/ansible-playbook-k8s.yml /home/ubuntu/petstore-repo/ansible/



# # Phase 4: Configure Jenkins

Access Jenkins: Open http://<jenkins_server_ip>:8090 in your browser.

Get Admin Password:

ssh -i petstore-key.pem ubuntu@<jenkins_server_ip>
sudo cat /var/lib/jenkins/secrets/initialAdminPassword

 Paste the password and complete the "Install suggested plugins" setup. The user-data script already installed the required plugins.

Add Credentials:

Sonar Token: Go to Manage Jenkins -> Credentials. Add a "Secret text" credential with ID sonar-token. Get the token from your SonarQube UI (http://<jenkins_server_ip>:9000).

DockerHub: Add a "Username with password" credential with ID dockerhub-creds.

Ansible/K8s SSH Key: Add a "SSH Username with private key" credential with ID k8s-ssh-key. Choose "Enter directly" and paste the contents of your petstore-key.pem file. The username is ubuntu.

Configure Tools:

Go to Manage Jenkins -> Global Tool Configuration.

Add JDK (Name: jdk17).

Add Maven (Name: Maven 3.9.6).

Add OWASP (Name: OWASP).


## Create Pipeline:

New Item -> Pipeline -> Name: petstore-pipeline.

Under Pipeline, select "Pipeline script from SCM".

SCM: Git

Repository URL: https://github.com/lastoyster/petstore-repo.git

Script Path: jenkins/Jenkinsfile (or just Jenkinsfile if it's in your root).

Save.


# Phase 5: Run the Build!

Click "Build Now" on your petstore-pipeline job.

The pipeline will run all stages. 
The final stage will SSH to your Ansible server, which will then use Ansible to run kubectl apply on your K8s master.

Access Your App:

Wait 2-3 minutes for the deployment and ALB to sync.

Go to the petstore_app_dns URL from the Terraform output:

http://<alb-dns-name>.us-east-1.elb.amazonaws.com


## Phase 6: Clean Up

To destroy all AWS resources (EC2, ALB, SGs, etc.), run:

terraform destroy -auto-approve
