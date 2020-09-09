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
                ]) {
                    sh 'make build'
                }
            }
        }
        stage('Send qcow over to vmhost') {
            steps {
                withCredentials([
                    sshUserPrivateKey(
                        credentialsId: 'jenkins-boot-volume',
                        keyFileVariable: 'STORAGE_USER_KEY',
                        usernameVariable: 'STORAGE_USER_NAME'
                        )
                ]) {
                    sh 'cat $STORAGE_USER_KEY > ssh_keys/id_rsa_boot_storage'
                    sh 'scp -o "StrictHostKeyChecking=no" -i ssh_keys/id_rsa_boot_storage output-ubuntu18.04_baseos/* $STORAGE_USER_NAME@192.168.122.1:/zpools/vmhost_qcow/boot/'
                }
            }
        }
    }
}
