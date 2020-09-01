@Library('github.com/releaseworks/jenkinslib') _

pipeline {
  agent any

  tools {
    maven 'M3'
    terraform 'terra'
  }
  environment {
    AWS_DEFAULT_REGION = 'eu-central-1'
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
    }*
    stage("Staging") {
      when {
        branch 'feature/*'
        changelog '*test*'
      }*
      steps {
        withCredentials([[$class: 'UsernamePasswordMultiBinding', 
          credentialsId: 'aws-iam', 
          usernameVariable: 'AWS_ACCESS_KEY_ID', 
          passwordVariable: 'AWS_SECRET_ACCESS_KEY']]) {
          sh 'terraform workspace select default'
          sh 'terraform init -input=false'
          sh 'terraform refresh'
          //sh 'terraform workspace new `date +"%y%m%d%H%M%S"`'
          sh 'terraform apply -input=false -auto-approve --target=aws_instance.Staging'
        }
      }
    }*/
    stage("Deploy") {/*
      when {
        branch 'master'
      }*/
      steps {
        script{
          withCredentials([[$class: 'UsernamePasswordMultiBinding', 
          credentialsId: 'aws-iam', 
          usernameVariable: 'AWS_ACCESS_KEY_ID', 
          passwordVariable: 'AWS_SECRET_ACCESS_KEY']]) {
            sh 'terraform init -input=false'
            backend_id = sh (returnStdout: true, script: 'echo `terraform output backend-id`').trim()
            sh 'terraform apply -input=false -auto-approve --target=aws_instance.Backup'
            backup_id = sh (returnStdout: true, script: 'echo `terraform output backup-id`').trim()
            sh 'aws ec2 wait instance-running --instance-ids $backup_id'
            //sh 'sleep 45'
            echo "backend id = $backend_id"
            echo "backup id = $backup_id"
            command_id = sh (returnStdout: true, script: '''
            echo `aws ssm send-command \
            --instance-ids $backend_id \
            --document-name "AWS-RunShellScript" \
            --comment "upgrade artifact" \
            --cli-input-json file://update.json \
            --output text \
            --query "Command.CommandId"`
            ''').trim()
            sh 'while [ `aws ssm list-commands --command-id $command_id | egrep InProgress` ]; do sleep 10; done'
            sh 'aws ssm list-commands --command-id $command_id | egrep Success'
            val_command_id = sh (returnStdout: true, script: '''
            echo `aws ssm send-command \
            --instance-ids $backend_id \
            --document-name "AWS-RunShellScript" \
            --comment "validate deployment" \
            --cli-input-json file://validate.json \
            --output text \
            --query "Command.CommandId"`
            ''').trim()
            sh 'while [ `aws ssm list-commands --command-id $val_command_id | egrep InProgress` ]; do sleep 10; done'
            sh 'aws ssm list-commands --command-id $val_command_id | egrep Success'
            sh 'terraform destroy -input=false -auto-approve --target=aws_instance.Backup'
          }
        }
      }/*
      post  {
        always{
          echo "========always========"
          sh 'terraform destroy -input=false -auto-approve --target=aws_instance.Backup'
        }
      }*/
    }
  }
}
