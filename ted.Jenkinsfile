pipeline {
  agent any

  tools {
    maven 'M3'
  }
  stages {
    stage('Env') {
      steps {
        sh 'env'
      }
    }
    stage('Pull') {
      steps {
        git url: 'git@github.com:BLsolomon/terraform-ted-search.git', branch: 'dev', credentialsId: 'admin'
      }
    }
    stage('Build') {
      steps {
        dir('app') {
          sh 'mvn clean'
          sh 'mvn verify'
        }
      }
    }
    stage('Test') {
      steps {
        sh "docker-compose -f ted.yml up static && docker-compose -f ted.yml up -d mem prod ng"
        sh 'docker-compose -f ted.yml up e2e'
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
