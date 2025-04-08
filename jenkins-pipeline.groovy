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
