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
                        sh "curl --silent https://cloud-images.ubuntu.com/releases/bionic/release/SHA256SUMS | awk  '/ubuntu-18.04-server-cloudimg-amd64.img/ {print \$1}' > iso_256_checksum.txt" 
                        sh 'sed -ie "s/REPLACE_THIS_WITH_ACTUAL_VALUE/$(cat iso_256_checksum.txt)/g" variables.json'
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
        stage('Send qcow over to vmhosts') {
            steps {
                withCredentials([
                    sshUserPrivateKey(
                        credentialsId: 'jenkins-automation-user',
                        keyFileVariable: 'JENKINS_USER_KEY',
                        usernameVariable: 'JENKINS_USER_NAME'
                        )
                ]) {
                    sh 'cat $JENKINS_USER_KEY > ssh_keys/id_ed25519_jenkins'
                    sh 'chmod 600 ssh_keys/id_ed25519_jenkins'
                    sh 'sed -i -e \'/^$/d\' ssh_keys/id_ed25519_jenkins'
                    sh 'rsync -a  --rsync-path="sudo rsync"  -e "ssh -o StrictHostKeyChecking=no -i ssh_keys/id_ed25519_jenkins" output-ubuntu18.04_baseos/ubuntu18.04_baseos.qcow2 $JENKINS_USER_NAME@vmhost01:/zpools/vmhost_qcow/boot/ubuntu18.04_baseos_latest.qcow2  --progress'
                    sh 'ssh -o StrictHostKeyChecking=no -i ssh_keys/id_ed25519_jenkins $JENKINS_USER_NAME@vmhost01 "sudo chown libvirt-qemu:kvm /zpools/vmhost_qcow/boot/ubuntu18.04_baseos_latest.qcow2"'
                    sh 'rsync -a  --rsync-path="sudo rsync"  -e "ssh -o StrictHostKeyChecking=no -i ssh_keys/id_ed25519_jenkins" output-ubuntu18.04_baseos/ubuntu18.04_baseos.qcow2 $JENKINS_USER_NAME@vmhost02:/zpools/vmhost_qcow/boot/ubuntu18.04_baseos_latest.qcow2  --progress'
                    sh 'ssh -o StrictHostKeyChecking=no -i ssh_keys/id_ed25519_jenkins $JENKINS_USER_NAME@vmhost02 "sudo chown libvirt-qemu:kvm /zpools/vmhost_qcow/boot/ubuntu18.04_baseos_latest.qcow2"'
                }
            }
        }
        stage('Clean up everything') {
            steps {
                    sh 'make clean'
                }
            }
    }
    post {
        failure {
            steps {
                sh 'make clean'
            }
        }
    }
}
