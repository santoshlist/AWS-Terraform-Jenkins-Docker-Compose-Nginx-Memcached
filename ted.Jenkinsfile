pipeline {
    agent any

    stages {
        stage('Pull') {
            steps {
                git url: 'git@github.com:BLsolomon/terraform-ted-search.git', branch: 'dev', credentialsId: 'admin'
            }
        }
        stage('Build') {
            dir('app') {
                steps {
                    sh 'mvn clean'
                    sh 'mvn verify'
                }
            }
        }
        stage('Test') {
            steps {
                sh "docker-compose up static && docker-compose up --build -d ng"
                sh 'docker-compose up e2e'
            }
            post{
                always{
                    echo "========always========"
                    sh 'docker-compose down'
                }
            }
        }
    }
}
