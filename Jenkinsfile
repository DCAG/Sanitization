pipeline {
  agent any
  stages {
    stage('Stage1') {
      steps {
        //powershell(script: 'Write-Host "Hello"', encoding: 'utf8', label: 'Hello', returnStatus: true, returnStdout: true)
        shell(script: 'echo "Hello"')
      }
    }
  }
}
