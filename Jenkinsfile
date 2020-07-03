pipeline {
    agent any

    stages {
        stage('Setup build') {
            steps {
                checkout scm
                script {
                    withCredentials([
                        sshUserPrivateKey(
                            credentialsId: 'packer-ssh-pair',
                            keyFileVariable: 'SSH_KEY_FILE'
                        )
                    ]) {
                        sh 'cat $SSH_KEY_FILE > ssh_keys/id_rsa_packer'
                    }                    
                }
            }
        }
        stage('Build VM') {
            steps {
                sh('make build')
            }
        }
        stage('Clean up output') {
            steps {
                sh('make clean')
            }
        }
    }
}
