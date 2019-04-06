pipeline {
  agent any
  stages {
    stage('Run PowerShell Script') {
      steps {
        powershell(script: 'Write-Host "Hello"', encoding: 'utf8', label: 'Hello', returnStatus: true, returnStdout: true)
      }
    }
  }
}
