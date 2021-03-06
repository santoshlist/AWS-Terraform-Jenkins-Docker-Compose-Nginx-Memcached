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
  }
  stages{
    stage("Delete"){
      steps{
        withCredentials([[$class: 'UsernamePasswordMultiBinding', 
        credentialsId: 'aws-iam', 
        usernameVariable: 'AWS_ACCESS_KEY_ID', 
        passwordVariable: 'AWS_SECRET_ACCESS_KEY']]) {
          sh "echo deleted workspaces in job number - ${env.BUILD_NUMBER} > `date +\"%y/%m/%d-%H:%M:%S\"`deleted-workspaces.txt"
          sh 'ls'
          sh 'for w in `t workspace list | grep -v default`; do \
                if [ \$(expr `date +"%y%m%d%H%M%S"` - $w) -gt 1500 ]; then \
                  echo $w >> `date +"%y/%m/%d-%H:%M:%S"`deleted-workspaces.txt      t workspace delete $w; done'
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