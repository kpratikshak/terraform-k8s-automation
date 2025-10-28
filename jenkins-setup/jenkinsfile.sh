#!/bin/bash
set -e -x

# Install Java (Jenkins requirement)
apt-get update
apt-get install -y openjdk-17-jdk

# Install Jenkins
curl -fsSL https://pkg.jenkins.io/debian-stable/jenkins.io-2023.key | tee /usr/share/keyrings/jenkins-keyring.asc > /dev/null
echo deb [signed-by=/usr/share/keyrings/jenkins-keyring.asc] https://pkg.jenkins.io/debian-stable binary/ | tee /etc/apt/sources.list.d/jenkins.list > /dev/null
apt-get update
apt-get install -y jenkins

# Change Jenkins port to 8090
sed -i 's/HTTP_PORT=8080/HTTP_PORT=8090/' /etc/default/jenkins
systemctl restart jenkins

# Install Docker
apt-get install -y docker.io
usermod -aG docker jenkins
systemctl restart jenkins

# Install SonarQube (in Docker)
docker run -d --name sonar -p 9000:9000 sonarqube:lts-community

# Install Trivy
apt-get install -y wget apt-transport-https gnupg
wget -qO - https://aquasecurity.github.io/trivy-repo/deb/public.key | apt-key add -
echo deb https://aquasecurity.github.io/trivy-repo/deb $(lsb_release -sc) main | tee -a /etc/apt/sources.list.d/trivy.list
apt-get update
apt-get install -y trivy

# Install kubectl
curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl

# Install Ansible (for the Jenkins plugin)
apt-add-repository --yes --update ppa:ansible/ansible
apt-get install -y ansible

# Install Jenkins Plugins
# Wait for Jenkins to be up
sleep 60 
JENKINS_CLI_URL="http://127.0.0.1:8090/jnlpJars/jenkins-cli.jar"
ADMIN_PASS=$(cat /var/lib/jenkins/secrets/initialAdminPassword)
wget $JENKINS_CLI_URL -O /tmp/jenkins-cli.jar

java -jar /tmp/jenkins-cli.jar -s http://127.0.0.1:8090 -auth admin:$ADMIN_PASS install-plugin ansible kubernetes kubernetes-cli jdk sonar maven-invoker dependency-check-pipeline docker-workflow
java -jar /tmp/jenkins-cli.jar -s http://127.0.0.1:8090 -auth admin:$ADMIN_PASS safe-restart
