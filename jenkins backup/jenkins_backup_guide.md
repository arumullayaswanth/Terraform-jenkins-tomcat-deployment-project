
# 🧠 Project: Jenkins Automated Backup to AWS S3

This guide walks you step-by-step through setting up an EC2 instance, installing Jenkins, and automating daily backups to an AWS S3 bucket.


# Prerequisites

✅ Jenkins installed on an EC2 instance (Ubuntu/CentOS).

✅ S3 bucket created in your AWS account (e.g., jenkins-backups-bucket).

✅ EC2 instance has IAM Role OR AWS CLI configured.

✅ Your private key .pem file to connect to EC2.

---

## 🚀 Step-by-Step Beginner Guide

### 🔹 STEP 1: Create an AWS EC2 Instance

1. Sign in to [AWS Console](https://aws.amazon.com/)
2. Search for “EC2” in the top search bar and click **EC2** under “Compute”.
3. Click **"Launch Instance"**
   - Name: `jenkins-server`
   - OS: Amazon Linux 2
   - Instance type: `t2.micro` (Free tier)
   - Key Pair: Create new, name it `jenkins-key`, download `.pem` file.
4. Click **Launch Instance**

---

### 🔹 STEP 2: Connect to Your EC2 via SSH

```bash
mv ~/Downloads/jenkins-key.pem ~/.ssh/
chmod 400 ~/.ssh/jenkins-key.pem
ssh -i ~/.ssh/jenkins-key.pem ec2-user@<your-ec2-public-ip>
```

---

### 🔹 STEP 3: Install Jenkins

#### On Amazon Linux:
```bash
sudo -i
#STEP-1: INSTALLING GIT JAVA-1.8.0 MAVEN 
yum install git java-1.8.0-openjdk maven -y

#STEP-2: GETTING THE REPO (jenkins.io --> download -- > redhat)
sudo wget -O /etc/yum.repos.d/jenkins.repo https://pkg.jenkins.io/redhat-stable/jenkins.repo
sudo rpm --import https://pkg.jenkins.io/redhat-stable/jenkins.io-2023.key

#STEP-3: DOWNLOAD JAVA11 AND JENKINS
#amazon-linux-extras install java-openjdk11 -y
sudo dnf install java-21-amazon-corretto -y
sudo yum install java-21-amazon-corretto -y
sudo amazon-linux-extras enable corretto21

yum install jenkins -y


update-alternatives --config java
# *+ 2           /usr/lib/jvm/java-17-amazon-corretto.x86_64/bin/java(select this)


#STEP-4: RESTARTING JENKINS (when we download service it will on stopped state)
systemctl start jenkins.service
sudo systemctl enable jenkins
systemctl status jenkins.service

```

#### On Ubuntu:
```bash
sudo apt update
sudo apt install openjdk-21-jdk -y
wget -q -O - https://pkg.jenkins.io/debian/jenkins.io.key | sudo apt-key add -
sudo sh -c 'echo deb https://pkg.jenkins.io/debian-stable binary/ > /etc/apt/sources.list.d/jenkins.list'
sudo apt update
sudo apt install jenkins -y
sudo systemctl start jenkins
sudo systemctl enable jenkins
```

---

### 🔹 STEP 4: Access Jenkins in Browser

1. Open Security Group → Edit Inbound Rules → Add Rule:
   - Type: HTTP
   - Port: 8080
   - Source: Anywhere (0.0.0.0/0)

2. Open in browser:
```
http://<your-ec2-public-ip>:8080
```

3. Get password:
```bash
sudo cat /var/lib/jenkins/secrets/initialAdminPassword
```

---

### Step 5: Access Jenkins UI
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



### Jenkins Project Deploymen and do some actions

1. Do some actions Jenkins and build and test and deployy And after finally you have go and verify your deployment.

2. Create a jenkins pipeline job and deploy your project
3. Now let us see the process how to set the backup Jenkins



### 🔹 STEP 5: Create an S3 Bucket

1. Go to [S3 Console](https://s3.console.aws.amazon.com/s3/)
2. Click **Create bucket**
   - Name: `jenkins-backup-123`
   - Uncheck "Block all public access"
   - Click Create

---

### 🔹 STEP 6: Attach IAM Role to EC2

1. Go to IAM → Roles → **Create role**
2. Choose **EC2** service
3. Create new policy with:
```json
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Action": "s3:PutObject",
      "Resource": "arn:aws:s3:::jenkins-backup-123/*"
    }
  ]
}
```
4. Attach policy, name role `jenkins-s3-role`
5. Go to EC2 → Actions → Security → Modify IAM Role → Attach this role

---

### 🔹 STEP 7: Install AWS CLI

#### On Amazon Linux:
```bash
sudo yum install awscli -y
```

#### On Ubuntu:
```bash
sudo apt install awscli -y
```

Test:
```bash
aws s3 ls
```

---

### 🔹 STEP 8: Create Backup Script

```bash
sudo vi /opt/jenkins_backup_to_s3.sh
```

Paste this:
```bash
#!/bin/bash

# Variables
BACKUP_DIR="/var/lib/jenkins"
BACKUP_FILE="/tmp/jenkins-backup-$(date +%F).tar.gz"
S3_BUCKET="s3://jkenkinsbackup/backups"

# Create tar.gz archive of Jenkins data
tar -czf "$BACKUP_FILE" "$BACKUP_DIR"

# Upload the archive to S3
aws s3 cp "$BACKUP_FILE" "$S3_BUCKET"

# Optionally remove local backup after upload
rm -f "$BACKUP_FILE"
```

Make executable:
```bash
sudo chmod +x /opt/jenkins_backup_to_s3.sh
```

---

### 🔹 STEP 9: Test the Script

```bash
sudo /opt/jenkins_backup_to_s3.sh
```

Check S3 for uploaded `.tar.gz` file.

---

### 🔹 STEP 10: Automate with Cron

```bash
#Install cronie (cron package for Amazon Linux / RHEL)
sudo yum install cronie -y
#Start and Enable the Cron Service
sudo systemctl enable crond
sudo systemctl start crond
#Check that it's running:
systemctl status crond
# Create Cron Job for Jenkins Backup
crontab -e
```

Add:
```bash
#Add this line at the bottom to run the script every day at 2:00 AM:
0 2 * * * /opt/jenkins_backup_to_s3.sh >> /var/log/jenkins_backup.log 2>&1
```

```bash
#View Cron Jobs Later
crontab -l
#To manually test the cron format or troubleshoot:
sudo cat /var/log/cron

```





---

## 🎉 You Did It!

You now have:
- ✅ EC2 running Jenkins
- ✅ S3 bucket for backups
- ✅ IAM role for access
- ✅ Backup script
- ✅ Daily cron job

---

## 💡 Optional Upgrades

- Add restore script
- Use S3 lifecycle rules to auto-delete old backups
- Encrypt backups
- Add Slack/email alerts







# 🔐 Jenkins Backup: Advanced Setup Guide

You've already set up automatic backups to S3 — awesome job! 🎉

Now let’s add more **powerful features** to your project, step by step, explained simply!

---

## 🔁 1. Restore Jenkins Backups from S3

### ✅ Step 1: Download Backup from S3

SSH into your EC2 and run:
```bash
aws s3 ls s3://jenkins-backup-123/backups/
```

Find the backup you want, then:
```bash
aws s3 cp s3://jenkins-backup-123/backups/jenkins-backup-YYYY-MM-DD.tar.gz /tmp/
```

### ✅ Step 2: Stop Jenkins Before Restore

```bash
sudo systemctl stop jenkins
```

### ✅ Step 3: Extract Backup

```bash
sudo tar -xzf /tmp/jenkins-backup-YYYY-MM-DD.tar.gz -C /
```

### ✅ Step 4: Start Jenkins Again

```bash
sudo systemctl start jenkins
```

You're back in business! 🚀

---

## 📧 2. Send Email Notifications (Success or Fail)

### ✅ Step 1: Install `mailx`

#### On Amazon Linux:
```bash
sudo yum install mailx -y
```

#### On Ubuntu:
```bash
sudo apt install mailutils -y
```

### ✅ Step 2: Modify Script to Send Email

Edit the end of your `/opt/jenkins_backup_to_s3.sh`:

```bash
EMAIL="your@email.com"

if [ $? -eq 0 ]; then
  echo "Jenkins backup successful" | mail -s "Jenkins Backup Success" "$EMAIL"
else
  echo "Jenkins backup FAILED!" | mail -s "Jenkins Backup FAILED" "$EMAIL"
fi
```

Now you’ll get an email whether the backup worked or failed.

---

## 🗜️ 3. Compress Jenkins Logs to Save Space

### ✅ Step 1: Add log compression to your script

Edit `/opt/jenkins_backup_to_s3.sh` and add after the backup:

```bash
LOG_DIR="/var/log/jenkins"
tar -czf /tmp/jenkins-logs-$(date +%F).tar.gz "$LOG_DIR"
aws s3 cp /tmp/jenkins-logs-$(date +%F).tar.gz $S3_BUCKET/logs/
rm -f /tmp/jenkins-logs-*.tar.gz
```

This compresses your logs and stores them in `/logs/` folder in S3.

---

## 🔐 4. Enable Encryption on Your S3 Bucket

### ✅ Step 1: Go to S3 Console

1. Open your bucket: `jenkins-backup-123`
2. Click **Properties**
3. Scroll to **Default Encryption**
4. Click **Edit**
5. Turn on encryption using **Amazon S3 managed keys (SSE-S3)** or **AWS KMS**

Click Save.

Now all backups are encrypted! 🔐

---

## ✅ Done!

You now have:

- 🔁 Restore process
- 📧 Email notifications
- 🗜️ Log compression
- 🔐 Encrypted S3 backups

Let me know if you want to:
- Restore to a new EC2
- Use S3 lifecycle to delete old backups
- Send alerts to Slack



