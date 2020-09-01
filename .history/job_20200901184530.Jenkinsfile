pipeline{
  agent any

  triggers{ 
    cron('H/15 * * * *') 
  }
  tools {
    terraform 'terra'
  }
  environment {
    AWS_DEFAULT_REGION = 'eu-central-1'
    DATE = sh (returnStdout: true, script: 'echo `date +"%y-%m-%d_%H:%M:%S"`').trim()
    DELETED = "${DATE}-deleted-workspaces.txt"
    ACTIVE = "${DATE}-active-workspaces.txt"
  }
  post{
    always{
      emailext attachmentsPattern: '$DELETED, $ACTIVE'
      body: """Terraform workspaces state status report for date: $DATE \
      ${currentBuild.currentResult}: Job $JOB_NAME build ${BUILD_NUMBER}\n More info at: $BUILD_URL"""
      recipientProviders: [developers(), requestor()]
      subject: "terraform status report - Jenkins Build ${currentBuild.currentResult}: Job $JOB_NAME"
      to: 'bl.shlomi@gmail.com
    }
  }
  stages{
    stage('Pull') {
      steps {
        git url: 'git@github.com:BLsolomon/terraform-ted-search.git', branch: 'dev', credentialsId: 'admin'
      }
    }
    stage('Env') {
      steps {
        sh 'env'
      }
    }
    stage("Delete"){
      steps {
        withCredentials([[$class: 'UsernamePasswordMultiBinding', 
        credentialsId: 'aws-iam', 
        usernameVariable: 'AWS_ACCESS_KEY_ID', 
        passwordVariable: 'AWS_SECRET_ACCESS_KEY']]) {
          sh 'terraform init -input=false'
          sh 'echo "deleted workspaces in job - ${BUILD_TAG}" > $DELETED'
          sh 'ls'
          sh '''for w in `terraform workspace list | grep -v default`; do
                if [ \$(expr `date +"%y%m%d%H%M%S"` - $w) -gt 1500 ]; then
                  echo $w >> $DELETED
                  terraform workspace delete $w
                fi
              done'''
          sh 'ls'
          sh 'cat $DELETED'
        }
      }
    }
    stage("Report"){
      steps {
        withCredentials([[$class: 'UsernamePasswordMultiBinding', 
        credentialsId: 'aws-iam', 
        usernameVariable: 'AWS_ACCESS_KEY_ID', 
        passwordVariable: 'AWS_SECRET_ACCESS_KEY']]) {
          sh 'terraform init -input=false'
          sh 'echo "active workspaces report in job - ${BUILD_TAG}" > $ACTIVE'
          sh 'terraform workspace list >> $ACTIVE'
          sh 'ls'
          sh 'cat $DELETED'
          sh 'cat $ACTIVE'
        }
      }
    }
        
    }

}