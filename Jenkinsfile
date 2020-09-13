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
                        credentialsId: 'jenkins-automation-user',
                        keyFileVariable: 'JENKINS_USER_KEY',
                        usernameVariable: 'JENKINS_USER_NAME'
                        )
                ]) {
                    sh 'cat $JENKINS_USER_KEY > ssh_keys/id_ed25519'
                    sh 'chmod 400 ssh_keys/id_ed25519'
                    sh 'scp -o "StrictHostKeyChecking=no" -i ssh_keys/id_ed25519 output-ubuntu18.04_baseos/ubuntu18.04_baseos.qcow2 $JENKINS_USER_NAME@192.168.122.1:/zpools/vmhost_qcow/boot/ubuntu18.04_baseos_latest.qcow2'
                }
            }
        }
        stage('Clean up everything') {
            steps {
                    sh 'make clean'
                }
            }
    }
}