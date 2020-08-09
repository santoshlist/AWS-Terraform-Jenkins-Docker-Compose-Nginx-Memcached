@Library('github.com/releaseworks/jenkinslib') _

pipeline {
  agent any

  tools {
    maven 'M3'
    terraform 'terra'
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
    }/*
    stage('Build') {
      steps {
        dir('app') {
          sh 'mvn clean'
          sh 'mvn verify'
        }
      }
    }/*
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
    }*
    stage("Publish") {
      steps {
        withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: 'aws-iam', usernameVariable: 'AWS_ACCESS_KEY_ID', passwordVariable: 'AWS_SECRET_ACCESS_KEY']]) {
          AWS("--region=eu-central-1 s3 cp app/target/embedash-1.1-SNAPSHOT.jar s3://16-ted-search/app/")
        }
      }
    }*/
    stage("Deploy") {
      steps {
        withCredentials([[$class: 'UsernamePasswordMultiBinding', credentialsId: 'aws-iam', usernameVariable: 'AWS_ACCESS_KEY_ID', passwordVariable: 'AWS_SECRET_ACCESS_KEY']]) {
          sh 'terraform --version'
          sh 'terraform init -input=false'
          sh 'terraform plan'
          sh 'terraform apply -input=false -auto-approve --target=aws_instance.Backup'
          AWS("--region=eu-central-1 ssm describe-instance-information \
	          --instance-information-filter-list key=InstanceIds,valueSet=`cat id_backup.txt`")
        }
        post  {
          always{
            echo "========always========"
            sh 'docker-compose down'
          }
        }
      }
    }
  }
}
