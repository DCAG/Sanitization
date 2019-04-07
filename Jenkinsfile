pipeline {
  agent any
  stages {
    stage('Prepare') {
      agent any
      steps {
        sh 'echo "hello"'
        powershell(script: 'Get-ChildItem "env:\\"', returnStatus: true, returnStdout: true)
      }
    }
    stage('Approval') {
      steps {
        input(message: 'Approve or Decline', id: '1', ok: 'Approve')
        echo 'Message'
      }
    }
    stage('Build') {
      steps {
        powershell(script: '$ENV:WORKSPACE/build.ps1', returnStatus: true, returnStdout: true)
      }
    }
  }
}