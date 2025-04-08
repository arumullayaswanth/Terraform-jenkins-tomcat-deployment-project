# DevOps Pipeline Setup with Terraform, Jenkins (Master-Slave), and Tomcat on AWS EC2


## Step 1: Launch EC2 and Install Terraform
1. Launch an EC2 instance.(Name:Terraform)
2. Connect to the EC2 instance via SSH.


## Step 2: Grant Permissions to Terraform
1. Navigate to **IAM (Identity and Access Management)**.
2. Go to **Users** → Click **Create User**.
3. Set **User Name** as `terraform`.
4. Click **Next** → **Set Permissions** → **Permission Options**.
5. Select **Attach Policies Directly** → Choose **Administrator Access**.
6. Click **Next** → **Create User**.
7. Open the **terraform user** profile.
8. Go to **Security Credentials** → **Access Key** → **Create Access Key**.
9. Select **Use Case** → **CLI**.
10. Confirm by selecting "I understand the recommendation and want to proceed".
11. Click **Next** → **Create Access Key**.
12. Download the **.csv file**.

---

## Step 3: Connect to Terraform EC2 Instance and Switch to Superuser

```sh
ssh -i <your-key.pem> ec2-user@<terraform-ec2-public-ip>
sudo -i
```

---

## Step 4: Configure AWS CLI on EC2

```sh
aws configure
```

**Provide the required values:**

- aws\_access\_key\_id = YOUR\_ACCESS\_KEY
- aws\_secret\_access\_key = YOUR\_SECRET\_KEY
- region = us-east-1
- output = table

**Verify configuration:**

```sh
aws configure list
aws sts get-caller-identity
```

---

## Step 5: Install Terraform on EC2
**Create a script:**
   ```sh
   vim terraform.sh
   ```
**Add the following content:**
   ```sh
   # Step 1: Install Required Packages
   sudo yum install -y yum-utils shadow-utils

   # Step 2: Add the HashiCorp Repository
   sudo yum-config-manager --add-repo https://rpm.releases.hashicorp.com/AmazonLinux/hashicorp.repo

   # Step 3: Install Terraform
   sudo yum -y install terraform
   terraform -version
   ```
**Run the script:**
   ```sh
   sh terraform.sh
   ```
---

## Step 6: Install Jenkins on EC2
**Create a script:**
   ```sh
   vim Jenkins.sh
   ```

**Add the following content:**
   ```sh
   # Install required packages
   yum install git java-1.8.0-openjdk maven -y

   # Add Jenkins repository
   sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
   sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key

   # Install Java and Jenkins
   sudo yum install java-17-amazon-corretto -y
   yum install jenkins -y
   update-alternatives --config java

   # Start Jenkins service
   systemctl start jenkins.service
   systemctl status jenkins.service
   ```

**Run the script:**
   ```sh
   sh Jenkins.sh
   ```
---

## Step 7: Retrieve Jenkins Initial Admin Password
```sh
cat /var/lib/jenkins/secrets/initialAdminPassword
```
Copy the password for the next step.

---

## Step 8: Access Jenkins UI
1. Copy the public IP address of your EC2 instance.
2. Open a browser and enter:
   ```
   http://<Public-IP>:8080
   ```
3. Paste the **initial admin password**.
4. Install **suggested plugins**.
5. Create the **first admin user**:
   - Username
   - Password
   - Full Name
   - Email
6. Click **Save and Continue** → **Save and Finish** → **Start using Jenkins**.

## Step 9: Configure Terraform Credentials in Jenkins
1. Open **Jenkins Dashboard** → **Manage Jenkins**.
2. Navigate to **Credentials** → **System** → **Global Credentials (unrestricted)**.
3. Click **Add Credentials**:
   - **Kind**: Select **Secret Text**
   - **Secret**: Enter your **AWS Access Key**(****************)
   - **ID**: `accesskey`
   - **Description**: Enter a meaningful description
4. Click **Save**.
5. Add another credential:
   - **Kind**: Select **Secret Text**
   - **Secret**: Enter your **AWS Secret Key**(******************)
   - **ID**: `secretkey`
   - **Description**: Enter a meaningful description
6. Click **Save**.

## Step 10: Create a Jenkins Pipeline Job for Terraform
1. Navigate to **Jenkins Dashboard** → **New Item**.
2. Enter **Name**: `terraform-project`.
3. Select **Pipeline** → Click **OK**.
4. Under **Pipeline Configuration**:
   - **This project is parameterized** → **Add Parameter** → **Choice Parameter**
   - **Name**: `action`
   - **Choices**: `apply` and `destroy`
5. Add the following pipeline script:
6. **Pipeline Script:**
   
 ```groovy
//Automating Infrastructure with Jenkins: Running Terraform Scripts using Jenkins Pipeline
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
6. Click **Save**.

---

## Step 11: Build with Parameters
1. Open **Jenkins Dashboard** → Select **terraform-project**.
2. Click **Build with Parameters**.
3. Choose **action** → Select `apply`.
4. Click **Build**.

## Step 12: Verify Terraform Deployment
1. SSH into your Terraform EC2 instance.
2. Run the following commands:
   ```sh
   cd /var/lib/jenkins/workspace/terraform-project
   ll
   ```
3. List Terraform state:
   ```sh
   terraform state list
   ```
---
## Step 13–26: Jenkins Master & Slave Configuration, Tomcat Setup, WAR Deployment


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

