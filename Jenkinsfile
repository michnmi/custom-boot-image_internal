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
                        sh "curl --silent https://cloud-images.ubuntu.com/releases/22.04/release/SHA256SUMS | awk  '/ubuntu-22.04-server-cloudimg-amd64.img/ {print \$1}' > iso_256_checksum-22.04.txt" 
                        sh 'sed -ie "s/REPLACE_THIS_WITH_ACTUAL_VALUE/$(cat iso_256_checksum-22.04.txt)/g" variables-22.04.json'
                    }                    
                }
            }
        }
        stage('Build cloud VM') {
            steps {
              //  githubNotify account: 'michnmi', context: "$env.JOB_BASE_NAME - $env.BUILD_DISPLAY_NAME", credentialsId: 'Github credentials', description: '', gitApiUrl: '', repo: 'custom-boot-image_internal', sha: "$env.GIT_COMMIT", status: 'PENDING', targetUrl: "$env.RUN_DISPLAY_URL"
                retry(3) {
                    withCredentials([
                        string(
                                credentialsId: 'Ansible-Vault password',
                                variable: 'VAULT_PASSWD'
                            )
                    ]) {
                        sh 'make clean'
                        sh 'make generate_iso'
                        sh 'make build'
                    }
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
                    sh 'rsync -a  --rsync-path="sudo rsync"  -e "ssh -o StrictHostKeyChecking=no -i ssh_keys/id_ed25519_jenkins" output-ubuntu22.04_baseos/ubuntu22.04_baseos.qcow2 $JENKINS_USER_NAME@vmhost01:/vmhost_qcow/boot/ubuntu22.04_baseos_latest.qcow2  --progress'
                    sh 'ssh -o StrictHostKeyChecking=no -i ssh_keys/id_ed25519_jenkins $JENKINS_USER_NAME@vmhost01 "sudo chown libvirt-qemu:kvm /vmhost_qcow/boot/ubuntu22.04_baseos_latest.qcow2"'
                    sh 'ssh -o StrictHostKeyChecking=no -i ssh_keys/id_ed25519_jenkins $JENKINS_USER_NAME@vmhost01 "sudo chmod 660 /vmhost_qcow/boot/ubuntu22.04_baseos_latest.qcow2"'
                    sh 'rsync -a  --rsync-path="sudo rsync"  -e "ssh -o StrictHostKeyChecking=no -i ssh_keys/id_ed25519_jenkins" output-ubuntu22.04_baseos/ubuntu22.04_baseos.qcow2 $JENKINS_USER_NAME@vmhost02:/zpools/vmhost_qcow/boot/ubuntu22.04_baseos_latest.qcow2  --progress'
                    sh 'ssh -o StrictHostKeyChecking=no -i ssh_keys/id_ed25519_jenkins $JENKINS_USER_NAME@vmhost02 "sudo chown libvirt-qemu:kvm /vmhost_qcow/boot/ubuntu22.04_baseos_latest.qcow2"'
                    sh 'ssh -o StrictHostKeyChecking=no -i ssh_keys/id_ed25519_jenkins $JENKINS_USER_NAME@vmhost02 "sudo chmod 660 /vmhost_qcow/boot/ubuntu22.04_baseos_latest.qcow2"'
                    sh 'rsync -a  --rsync-path="sudo rsync"  -e "ssh -o StrictHostKeyChecking=no -i ssh_keys/id_ed25519_jenkins" output-ubuntu22.04_baseos/ubuntu22.04_baseos.qcow2 $JENKINS_USER_NAME@vmhost03:/vmhost_qcow/boot/ubuntu22.04_baseos_latest.qcow2  --progress'
                    sh 'ssh -o StrictHostKeyChecking=no -i ssh_keys/id_ed25519_jenkins $JENKINS_USER_NAME@vmhost03 "sudo chown libvirt-qemu:kvm /vmhost_qcow/boot/ubuntu22.04_baseos_latest.qcow2"'
                    sh 'ssh -o StrictHostKeyChecking=no -i ssh_keys/id_ed25519_jenkins $JENKINS_USER_NAME@vmhost03 "sudo chmod 660 /vmhost_qcow/boot/ubuntu22.04_baseos_latest.qcow2"'
                }
            }
        }
        stage('Update image to be used - vmhost01.') {
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
                    sh 'ssh -o StrictHostKeyChecking=no -i ssh_keys/id_ed25519_jenkins $JENKINS_USER_NAME@vmhost01 "sudo mv /vmhost_qcow/boot/ubuntu22.04_baseos.qcow2 /vmhost_qcow/boot/ubuntu22.04_baseos_previous.qcow2"'
                    sh 'ssh -o StrictHostKeyChecking=no -i ssh_keys/id_ed25519_jenkins $JENKINS_USER_NAME@vmhost01 "sudo cp -p /vmhost_qcow/boot/ubuntu22.04_baseos_latest.qcow2 /vmhost_qcow/boot/ubuntu22.04_baseos.qcow2"'
                }
            }
        }
        stage('Update image to be used - vmhost02.') {
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
                    sh 'ssh -o StrictHostKeyChecking=no -i ssh_keys/id_ed25519_jenkins $JENKINS_USER_NAME@vmhost02 "sudo mv /vmhost_qcow/boot/ubuntu22.04_baseos.qcow2 /vmhost_qcow/boot/ubuntu22.04_baseos_previous.qcow2"'
                    sh 'ssh -o StrictHostKeyChecking=no -i ssh_keys/id_ed25519_jenkins $JENKINS_USER_NAME@vmhost02 "sudo cp -p /vmhost_qcow/boot/ubuntu22.04_baseos_latest.qcow2 /vmhost_qcow/boot/ubuntu22.04_baseos.qcow2"'
                }
            }
        }
        stage('Update image to be used - vmhost03.') {
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
                    sh 'ssh -o StrictHostKeyChecking=no -i ssh_keys/id_ed25519_jenkins $JENKINS_USER_NAME@vmhost03 "sudo mv /vmhost_qcow/boot/ubuntu22.04_baseos.qcow2 /vmhost_qcow/boot/ubuntu22.04_baseos_previous.qcow2"'
                    sh 'ssh -o StrictHostKeyChecking=no -i ssh_keys/id_ed25519_jenkins $JENKINS_USER_NAME@vmhost03 "sudo cp -p /vmhost_qcow/boot/ubuntu22.04_baseos_latest.qcow2 /vmhost_qcow/boot/ubuntu22.04_baseos.qcow2"'
                }
            }
        }

        stage('Clean up everything') {
            steps {
                    sh 'make clean'
                       // githubNotify account: 'michnmi', context: "$env.JOB_BASE_NAME - $env.BUILD_DISPLAY_NAME", credentialsId: 'Github credentials', description: '', gitApiUrl: '', repo: 'custom-boot-image_internal', sha: "$env.GIT_COMMIT", status: 'SUCCESS', targetUrl: "$env.RUN_DISPLAY_URL"
                       slackSend color: "good", message: "Custom boot image has been built. (<${env.BUILD_URL}|${env.JOB_NAME} #${env.BUILD_NUMBER}>)"
                }
            }
    }
    post {
        failure {
            sh 'make clean'
          //      githubNotify account: 'michnmi', context: "$env.JOB_BASE_NAME - $env.BUILD_DISPLAY_NAME", credentialsId: 'Github credentials', description: '', gitApiUrl: '', repo: 'custom-boot-image_internal', sha: "$env.GIT_COMMIT", status: 'FAILURE', targetUrl: "$env.RUN_DISPLAY_URL"
                slackSend color: "danger", message: "Custom boot image has failed building. (<${env.BUILD_URL}|${env.JOB_NAME} #${env.BUILD_NUMBER}>)"
        }
    }
}
