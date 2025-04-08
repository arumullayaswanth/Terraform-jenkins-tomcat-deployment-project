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
