# DevOps Pipeline Setup with Terraform, Jenkins (Master-Slave), and Tomcat on AWS EC2
Deploy a web application using Jenkins to a Tomcat server. Everything is provisioned and configured using Terraform.
<table>
  <tr>
    <td align="center" style="background-color:#f0f8ff; padding:10px;">
      <img src="https://github.com/arumullayaswanth/Devops-Software-Installation-Project/blob/e6dd7184debf213d1cd3b696a85df6d62ba1234c/Pictures/DevOps%20Pipeline%20Setup%20with%20Terraform%2C%20Jenkins%20(Master-Slave)%2C%20and%20Tomcat%20on%20AWS%20EC2.png" width="90%">
      <br><b style="color:#1f75fe;">🔵 DevOps Pipeline Setup with Terraform, Jenkins (Master-Slave), and Tomcat on AWS EC2</b>
    </td>
  </tr>
</table>

## Step 1: Launch EC2 and Install Terraform
1. Launch an EC2 instance.(Name:Terraform)
2. Connect to the EC2 instance via SSH.

---

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
   http://<terraform Public-IP>:8080
   ```
3. Paste the **initial admin password**.
4. Install **suggested plugins**.
5. Create the **first admin user**:
   - Username
   - Password
   - Full Name
   - Email
6. Click **Save and Continue** → **Save and Finish** → **Start using Jenkins**.

---

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

---

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
7. Click **Save**.

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
## AWS infrastructure setup is completed now
---

## Step 13–26: Jenkins Master & Slave Configuration, Tomcat Setup, WAR Deployment
---
## Step 13: Connect to Jenkins-Master EC2
```bash
sudo -i
hostnamectl set-hostname Jenkins-Master
sudo -i
```
---

## Step 14: Install Jenkins on Master
14.1. Create a script:
   ```sh
   vim Jenkins.sh
   ```
**14.2. Add the following content:**
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
**14.3. Run the script:**
   ```sh
   sh Jenkins.sh
   ```

**14.4.Retrieve Jenkins Initial Admin Password:**
```sh
cat /var/lib/jenkins/secrets/initialAdminPassword
```
Copy the password for the next step.

**14.5. Access Jenkins UI:**
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

---

## Step 15: Connect to Jenkins-Slave EC2 and Configure Jenkins Slave (Agent)

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
#STEP-1: INSTALLING GIT JAVA-1.8.0 MAVEN 
yum install git java-1.8.0-openjdk maven -y

#STEP-2: DOWNLOAD JAVA11 AND JENKINS
sudo yum install java-17-amazon-corretto -y
#update-alternatives --config java
# *+ 2   /usr/lib/jvm/java-17-amazon-corretto.x86_64/bin/java(select this)
java -version
```
Run:
```bash
sh jenkins-slave.sh
```
---

## Step 16: Install Tomcat in Jenkins-Slave
<table>
  <tr>
    <td align="center" style="background-color:#f0f8ff; padding:10px;">
      <img src="https://github.com/arumullayaswanth/Devops-Software-Installation-Project/blob/d08f8ca936c18e489df753fc012e18adf80d8568/Pictures/Install%20Apache%20Tomcat%20in%20Jenkins-1.png" width="90%">
      <br><b style="color:#1f75fe;">🔵 Install Apache Tomcat in Jenkins - 1</b>
    </td>
    <td align="center" style="background-color:#fff0f5; padding:10px;">
      <img src="https://github.com/arumullayaswanth/Devops-Software-Installation-Project/blob/d08f8ca936c18e489df753fc012e18adf80d8568/Pictures/Install%20Apache%20Tomcat%20in%20Jenkins-2.png" width="90%">
      <br><b style="color:#e60000;">🔴 Install Apache Tomcat in Jenkins - 2</b>
    </td>
  </tr>
</table>

## Prerequisites
- Jenkins is installed and running.
- Java 17 (Amazon Corretto) is installed.
- A Linux-based OS (Amazon Linux, CentOS, or Ubuntu).


**Step 16.1: Download and Extract Apache Tomcat:**
```sh
wget https://archive.apache.org/dist/tomcat/tomcat-9/v9.0.98/bin/apache-tomcat-9.0.98.tar.gz
```
```sh
tar -zxvf apache-tomcat-9.0.98.tar.gz
```

**Step 16.2: Configure Tomcat Users:**
Edit the `tomcat-users.xml` file to add admin credentials.
```sh
sed -i '55  a\<role rolename="manager-gui"/>' apache-tomcat-9.0.98/conf/tomcat-users.xml
```
```sh
sed -i '56  a\<role rolename="manager-script"/>' apache-tomcat-9.0.98/conf/tomcat-users.xml
```
```sh
sed -i '57  a\<user username="tomcat" password="523182" roles="manager-gui, manager-script"/>' apache-tomcat-9.0.98/conf/tomcat-users.xml
```
add
```sh
  <role rolename="manager-gui"/>
  <role rolename="manager-script"/>
  <user username="tomcat" password="523182" roles="manager-gui, manager-script"/>
</tomcat-users>
```
**Step 16.3: Modify Context.xml**
To allow remote access to Tomcat Manager:
```sh
sed -i '21d' apache-tomcat-9.0.98/webapps/manager/META-INF/context.xml
```
```sh
sed -i '22d' apache-tomcat-9.0.98/webapps/manager/META-INF/context.xml
```

**Step 16.4: Start Tomcat:**
```sh
sh apache-tomcat-9.0.98/bin/startup.sh
```

**Step 16.5: Verify Installation:**
Access Tomcat in the browser:
```
http://<your-server-ip>:8080
```
Log in using the configured username (`tomcat`) and password (`523182`).


**Step 16.6: Integrate Tomcat with Jenkins:**
1. Open Jenkins.
2. Go to **Manage Jenkins** > **Plugins** > **Available Plugins**.
3. Install **Deploy to Container Plugin**.> **Go back to the top page**
   

## Step-17: Configure Tomcat Credentials in Jenkins

***Step 17.1: Open Jenkins Dashboard:***

1. Log in to Jenkins.
2. Click on `Manage Jenkins`.
3. Navigate to `Credentials` > `System` > `Global credentials (unrestricted)`.

***Step 17.2: Add Tomcat Credentials:***

1. Click `Add Credentials`.
2. Enter the following details:
   - **Username:** `tomcat`
   - **Password:** `523182`
3. Click `Create`.

***Step 17.3: Copy Tomcat Credential ID:***

1. Go back to `Credentials`.
2. Find the newly created Tomcat credentials.
3. Copy the **Credential ID** for later use in Jenkins jobs.

Your Apache Tomcat server is now installed and linked to Jenkins! 🚀
---


## Step 18: Deploy WAR via Jenkins Pipeline
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

## Step 19: Verify WAR Deployment
```bash
cd /tmp/workspace/jenkins-project/target
ll
```

## Step 20: Access Tomcat in Browser
- URL: `http://<Tomcat-IP>:8080`
- Login: `tomcat` / `523182`
- Refresh to see deployed app

---

✅ **DevOps Infrastructure with Terraform + Jenkins + Tomcat is now ready!**

