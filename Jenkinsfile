pipeline {
  agent any
  stages {
    stage('Prepare') {
      agent any
      steps {
        sh 'echo "hello"'
        powershell(script: 'gci env:\\', returnStatus: true, returnStdout: true)
        input(message: 'Message', submitter: 'submitter', submitterParameter: 'submitter parameter', ok: 'Ok', id: '2')
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
        powershell(script: 'invoke-psake -build build.psake.ps1', returnStatus: true, returnStdout: true)
      }
    }
  }
}