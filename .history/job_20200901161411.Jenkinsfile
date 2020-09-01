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
      steps{
        withCredentials([[$class: 'UsernamePasswordMultiBinding', 
        credentialsId: 'aws-iam', 
        usernameVariable: 'AWS_ACCESS_KEY_ID', 
        passwordVariable: 'AWS_SECRET_ACCESS_KEY']]) {
          echo "DELETED = $DELETED"
          sh 'echo "DELETED = $DELETED"'
          sh 'echo "deleted workspaces in job number - ${BUILD_NUMBER}" > $DELETED'
          sh 'ls'
          sh '''for w in `terraform workspace list | grep -v default`; do \
                if [ \$(expr `date +"%y%m%d%H%M%S"` - $w) -gt 1500 ]; then \
                  echo $w >> $DELETED \
                  terraform workspace delete $w \
                fi \
              done'''
          sh 'ls'
          sh 'cat $DELETED'
        }
      }
        post{
            always{
                echo "========always========"
            }
            success{
                echo "========A executed successfully========"
            }
            failure{
                echo "========A execution failed========"
            }
        }
    }
}
post{
    always{
        echo "========always========"
    }
    success{
          echo "========pipeline executed successfully ========"
      }
      failure{
          echo "========pipeline execution failed========"
      }
  }
}