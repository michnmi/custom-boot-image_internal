pipeline {
    agent any

    stages {
        stage('Prepare build') {
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
        stage('Build cloud VM') {
            steps {
                withCredentials([
                    string(
                            credentialsId: 'Ansible-Vault password',
                            variable: 'VAULT_PASSWD'
                        )
                ])
                sh('make build')
            }
        }
    }
}
