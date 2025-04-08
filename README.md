# DevOps Pipeline Setup with Terraform, Jenkins (Master-Slave), and Tomcat on AWS EC2

## Step 1: Launch EC2 and Install Terraform
- Launch an EC2 instance (Name: **Terraform**).
- Connect via SSH.
- Install Terraform.

## Step 2: Grant Permissions to Terraform
- Go to IAM → Users → Create User.
- User Name: `terraform` → Permissions: Attach Administrator Access Policy.
- Create Access Key for CLI → Download the `.csv` file.

## Step 3: Switch to Root
```bash
sudo -i
```

## Step 4: Configure AWS CLI on EC2
```bash
aws configure
```
Provide:
- AWS Access Key ID
- AWS Secret Access Key
- Region: `us-east-1`
- Output format: `table`

Verify:
```bash
aws configure list
aws sts get-caller-identity
```

## Step 5: Install Terraform on EC2
Create a script:
```bash
vim terraform.sh
```
Content:
```bash
sudo yum install -y yum-utils shadow-utils
sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo
sudo yum -y install terraform
terraform -version
```
Run:
```bash
sh terraform.sh
```

## Step 6: Install Jenkins on Terraform EC2
Create a script:
```bash
vim Jenkins.sh
```
Content:
```bash
yum install git java-1.8.0-openjdk maven -y
sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
sudo yum install java-17-amazon-corretto -y
yum install jenkins -y
update-alternatives --config java
systemctl start jenkins.service
systemctl status jenkins.service
```
Run:
```bash
sh Jenkins.sh
```

## Step 7: Retrieve Jenkins Initial Admin Password
```bash
cat /var/lib/jenkins/secrets/initialAdminPassword
```

## Step 8: Access Jenkins UI
- Open: `http://<Public-IP>:8080`
- Paste password, install plugins, and create admin user.

## Step 9: Configure Terraform Credentials in Jenkins
- Jenkins Dashboard → Manage Jenkins → Credentials → System → Global → Add Credentials
  - **Kind**: Secret Text
  - **ID**: `accesskey` / `secretkey`

## Step 10: Create Jenkins Pipeline Job
Pipeline Script:
```groovy
pipeline {
    agent any
    environment {
        AWS_ACCESS_KEY_ID     = credentials('accesskey')
        AWS_SECRET_ACCESS_KEY = credentials('secretkey')
    }
    stages {
        stage('checkout') {
            steps {
                git 'https://github.com/arumullayaswanth/jenkins-tomcat-deployment-project.git'
            }
        }
        stage('init') {
            steps {
                sh 'terraform init'
            }
        }
        stage('validate') {
            steps {
                sh 'terraform validate'                
            }
        }
        stage('plan') {
            steps {
                sh 'terraform plan'
            }
        }
        stage('action') {
            steps {
                sh 'terraform $action --auto-approve'
            }
        }
    }
}
```

## Step 11: Build with Parameters
- Jenkins Dashboard → Select `terraform-project` → Build with Parameters → Action: apply

## Step 12: Verify Terraform Deployment
```bash
cd /var/lib/jenkins/workspace/terraform-project
ll
terraform state list
```

## Step 13: Connect to Jenkins-Master EC2
```bash
sudo -i
hostnamectl set-hostname Jenkins-Master
sudo -i
```

## Step 14: Install Jenkins on Master
Create `Jenkins.sh` with:
```bash
yum install git java-1.8.0-openjdk maven -y
sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key
sudo yum install java-17-amazon-corretto -y
yum install jenkins -y
update-alternatives --config java
systemctl start jenkins.service
systemctl status jenkins.service
```

## Step 15: Setup Jenkins-Slave EC2
```bash
sudo -i
hostnamectl set-hostname Jenkins-Slave
sudo -i
```
Script:
```bash
vim jenkins-slave.sh
```
Content:
```bash
yum install git java-1.8.0-openjdk maven -y
sudo yum install java-17-amazon-corretto -y
java -version
```
Run:
```bash
sh jenkins-slave.sh
```

## Step 16: Install Tomcat in Jenkins-Slave
```bash
sudo yum install java-17-amazon-corretto -y
wget https://archive.apache.org/dist/tomcat/tomcat-9/v9.0.98/bin/apache-tomcat-9.0.98.tar.gz
tar -zxvf apache-tomcat-9.0.98.tar.gz
```
Edit users:
```bash
sed -i '55  a\<role rolename="manager-gui"/>' apache-tomcat-9.0.98/conf/tomcat-users.xml
sed -i '56  a\<role rolename="manager-script"/>' apache-tomcat-9.0.98/conf/tomcat-users.xml
sed -i '57  a\<user username="tomcat" password="523182" roles="manager-gui, manager-script"/>' apache-tomcat-9.0.98/conf/tomcat-users.xml
```
Edit context:
```bash
sed -i '21d' apache-tomcat-9.0.98/webapps/manager/META-INF/context.xml
sed -i '22d' apache-tomcat-9.0.98/webapps/manager/META-INF/context.xml
```
Start:
```bash
sh apache-tomcat-9.0.98/bin/startup.sh
```

Access:
```url
http://<your-server-ip>:8080
```
Username: `tomcat`, Password: `523182`

## Step 17: Configure Jenkins Slave in Master
- Jenkins Dashboard → Manage Jenkins → Nodes → New Node
  - Name: `jenkins-slave`, Type: Permanent Agent
  - Remote root: `/tmp`, Labels: `jenkins-slave`
  - Launch via SSH → Host: <Private IP of slave>
  - Add SSH Credentials → Username: `ec2-user`, Key: <KeyPair>

## Step 18: Configure Tomcat Credentials in Jenkins
- Manage Jenkins → Credentials → Global
- Add Credentials:
  - Username: `tomcat`, Password: `523182`

## Step 19: Deploy WAR via Jenkins Pipeline
Pipeline Script:
```groovy
pipeline {
    agent {
        label 'jenkins-slave'
    }
    stages {
        stage('checkout') {
            steps {
                git "https://github.com/arumullayaswanth/jenkins-java-project.git"
            }
        }
        stage("Build"){
            steps {
                sh "mvn compile"
            }
        }
        stage("Test"){
            steps {
               sh "mvn test"
            }
        }
        stage("Artifact"){
            steps {
                sh "mvn clean package"
            }
        }
        stage("Deploy") {
            steps {
                deploy adapters:[
                    tomcat9(
                        credentialsId: "8eacad04-e5e7-462e-a155-8fc36b9e1c52",
                        path: " ",
                        url:"http://54.237.197.4:8080/"
                    )
                ],
                contextPath:"Netfilx",
                war:"target/*.war"
            }
        }
    }
}
```

## Step 20: Verify WAR Deployment
```bash
cd /tmp/workspace/jenkins-project/target
ll
```

## Step 21: Access Tomcat in Browser
- URL: `http://<Tomcat-IP>:8080`
- Login: `tomcat` / `523182`
- Refresh to see deployed app

---

✅ **DevOps Infrastructure with Terraform + Jenkins + Tomcat is now ready!**

