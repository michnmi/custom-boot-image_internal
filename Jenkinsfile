pipeline {
  agent any

  triggers {
    cron('H 0 * * *')
    pollSCM('*/3 * * * *')
  }

  
  environment {  
    GITHUB_ACCOUNT   = 'michnmi'
    GITHUB_REPO      = 'custom-boot-image_internal'
    GITHUB_CREDS_ID  = 'custom-vm-build'
    GITHUB_CONTEXT   = 'qcow-build'

    PACKER_SSH_CRED_ID    = 'packer-ssh-pair'
    VAULT_PASSWORD_CRED_ID = 'Ansible-Vault password'
    JENKINS_SSH_CRED_ID   = 'jenkins-automation-user'
  }

  options {
    timestamps()
    disableConcurrentBuilds()
  }

  stages {

    stage('Checkout & prepare') {
      steps {
        checkout scm

        script {
          env.COMMIT_SHA = sh(
            script: 'git rev-parse HEAD',
            returnStdout: true
          ).trim()

          echo "Building commit ${env.COMMIT_SHA} on branch ${env.BRANCH_NAME ?: 'N/A'}"

          githubNotify(
            credentialsId: env.GITHUB_CREDS_ID,
            account:       env.GITHUB_ACCOUNT,
            repo:          env.GITHUB_REPO,
            sha:           env.COMMIT_SHA,
            context:       env.GITHUB_CONTEXT,
            status:        'PENDING',
            description:   'Building qcow image…'
          )
        }

        // Prepare SSH key for packer
        withCredentials([
          sshUserPrivateKey(
            credentialsId: env.PACKER_SSH_CRED_ID,
            keyFileVariable: 'SSH_KEY_FILE'
          )
        ]) {
          sh '''
            set -eu
            mkdir -p ssh_keys
            cat "$SSH_KEY_FILE" > ssh_keys/id_rsa_packer
            chmod 600 ssh_keys/id_rsa_packer
          '''
        }

        // Fetch checksum and inject into variables file
          sh """
            set -eu
            echo "Fetching checksum for image: ${params.UBUNTU_IMAGE_NAME}"
            curl --silent "${params.UBUNTU_CHECKSUM_URL}" \\
              | awk -v img="${params.UBUNTU_IMAGE_NAME}" 'index(\$2, img) > 0 {print \$1; exit}' \\
              > "${params.UBUNTU_CHECKSUM_FILE}"
          
            echo "Checksum file content:"
            cat "${params.UBUNTU_CHECKSUM_FILE}"
          
            if [ ! -s "${params.UBUNTU_CHECKSUM_FILE}" ]; then
              echo "ERROR: checksum file is empty. Check UBUNTU_CHECKSUM_URL / UBUNTU_IMAGE_NAME."
              exit 1
            fi
          
            sed -ie "s/REPLACE_THIS_WITH_ACTUAL_VALUE/\$(cat ${params.UBUNTU_CHECKSUM_FILE})/g" "${params.VARS_FILE}"
          
            echo "Snippet of updated vars file:"
            grep -n 'sha256\\|REPLACE_THIS_WITH_ACTUAL_VALUE' "${params.VARS_FILE}" || true
          """

      }
    }

    stage('Build cloud VM qcow') {
      steps {
        retry(3) {
          withCredentials([
            string(
              credentialsId: env.VAULT_PASSWORD_CRED_ID,
              variable: 'VAULT_PASSWD'
            )
          ]) {
            sh '''
              set -eu
              make clean
              make generate_iso
              make build
            '''
          }
        }
      }
    }

    stage('Send qcow to vmhosts') {
      steps {
        withCredentials([
          sshUserPrivateKey(
            credentialsId: env.JENKINS_SSH_CRED_ID,
            keyFileVariable: 'JENKINS_USER_KEY',
            usernameVariable: 'JENKINS_USER_NAME'
          )
        ]) {
          script {
            def qcowLocal   = "${params.QCOW_OUTPUT_DIR}/${params.QCOW_OUTPUT_NAME}"
            def latestName  = "${params.QCOW_REMOTE_PATH}/ubuntu22.04_baseos_latest.qcow2"

            ['VMHOST1', 'VMHOST2'].each { hostParam ->
              def host = params[hostParam]
              echo "Syncing qcow to ${host}"

              sh """
                set -eu
                mkdir -p ssh_keys
                cat "$JENKINS_USER_KEY" > ssh_keys/id_ed25519_jenkins
                chmod 600 ssh_keys/id_ed25519_jenkins
                sed -i -e '/^\$/d' ssh_keys/id_ed25519_jenkins

                rsync -a --rsync-path="sudo rsync" \\
                  -e "ssh -o StrictHostKeyChecking=no -i ssh_keys/id_ed25519_jenkins" \\
                  "${qcowLocal}" \\
                  "${JENKINS_USER_NAME}@${host}:${latestName}" --progress

                ssh -o StrictHostKeyChecking=no -i ssh_keys/id_ed25519_jenkins \\
                  "${JENKINS_USER_NAME}@${host}" \\
                  "sudo chown libvirt-qemu:kvm ${latestName} && sudo chmod 660 ${latestName}"
              """
            }
          }
        }
      }
    }

    stage('Activate new image on vmhosts') {
      steps {
        withCredentials([
          sshUserPrivateKey(
            credentialsId: env.JENKINS_SSH_CRED_ID,
            keyFileVariable: 'JENKINS_USER_KEY',
            usernameVariable: 'JENKINS_USER_NAME'
          )
        ]) {
          script {
            def currentName = "${params.QCOW_REMOTE_PATH}/ubuntu22.04_baseos.qcow2"
            def previousName = "${params.QCOW_REMOTE_PATH}/ubuntu22.04_baseos_previous.qcow2"
            def latestName   = "${params.QCOW_REMOTE_PATH}/ubuntu22.04_baseos_latest.qcow2"

            ['VMHOST1', 'VMHOST2'].each { hostParam ->
              def host = params[hostParam]
              echo "Activating new image on ${host}"

              sh """
                set -eu
                mkdir -p ssh_keys
                cat "$JENKINS_USER_KEY" > ssh_keys/id_ed25519_jenkins
                chmod 600 ssh_keys/id_ed25519_jenkins
                sed -i -e '/^\$/d' ssh_keys/id_ed25519_jenkins

                ssh -o StrictHostKeyChecking=no -i ssh_keys/id_ed25519_jenkins \\
                  "${JENKINS_USER_NAME}@${host}" \\
                  "sudo mv ${currentName} ${previousName} || true && \\
                   sudo cp -p ${latestName} ${currentName}"
              """
            }
          }
        }
      }
    }

    stage('Clean up') {
      steps {
        sh '''
          set +e
          make clean
        '''
      }
    }
  }

  post {
    success {
      script {
        githubNotify(
          credentialsId: env.GITHUB_CREDS_ID,
          account:       env.GITHUB_ACCOUNT,
          repo:          env.GITHUB_REPO,
          sha:           env.COMMIT_SHA,
          context:       env.GITHUB_CONTEXT,
          status:        'SUCCESS',
          description:   'qcow image build and deploy succeeded'
        )
      }

      slackSend(
        color: "good",
        message: "Custom boot image has been built and deployed. (<${env.BUILD_URL}|${env.JOB_NAME} #${env.BUILD_NUMBER}>)"
      )
    }

    failure {
      script {
        // Best effort cleanup
        sh '''
          set +e
          make clean
        '''

        githubNotify(
          credentialsId: env.GITHUB_CREDS_ID,
          account:       env.GITHUB_ACCOUNT,
          repo:          env.GITHUB_REPO,
          sha:           env.COMMIT_SHA ?: env.GIT_COMMIT,
          context:       env.GITHUB_CONTEXT,
          status:        'FAILURE',
          description:   'qcow image build or deploy failed'
        )
      }

      slackSend(
        color: "danger",
        message: "Custom boot image build FAILED. (<${env.BUILD_URL}|${env.JOB_NAME} #${env.BUILD_NUMBER}>)"
      )
    }
  }
}
