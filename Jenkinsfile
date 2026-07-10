def IMAGE_VERSIONS = []

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
          IMAGE_VERSIONS = params.IMAGE_VERSIONS.split(',').collect { it.trim() }
          echo "Building versions: ${IMAGE_VERSIONS}"

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

        // Fetch and inject the real checksum into every version's vars file
        script {
          IMAGE_VERSIONS.each { v ->
            def varsFile = "variables-${v}.json"
            sh """
              set -eu
              sourceUrl=\$(grep -oP '"source_iso_url":\\s*"\\K[^"]+' "${varsFile}")
              imageName=\$(basename "\$sourceUrl")
              checksumUrl=\$(dirname "\$sourceUrl")/SHA256SUMS
              checksumFile="/tmp/ubuntu${v}_sha256.checksum"

              echo "Fetching checksum for \$imageName from \$checksumUrl"
              curl --silent "\$checksumUrl" \\
                | awk -v img="\$imageName" 'index(\$2, img) > 0 {print \$1; exit}' \\
                > "\$checksumFile"

              if [ ! -s "\$checksumFile" ]; then
                echo "ERROR: checksum file is empty for ${v}. Check source_iso_url in ${varsFile}."
                exit 1
              fi

              sed -ie "s/REPLACE_THIS_WITH_ACTUAL_VALUE/\$(cat \$checksumFile)/g" "${varsFile}"

              echo "Snippet of updated ${varsFile}:"
              grep -n 'sha256\\|REPLACE_THIS_WITH_ACTUAL_VALUE' "${varsFile}" || true
            """
          }
        }

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
            IMAGE_VERSIONS.each { v ->
              def outputName = sh(
                script: "grep -oP '\"output_vm_name\":\\s*\"\\K[^\"]+' variables-${v}.json",
                returnStdout: true
              ).trim()
              def qcowLocal  = "${params.QCOW_OUTPUT_DIR}/${outputName}"
              def latestName = "${params.QCOW_REMOTE_PATH}/boot/ubuntu${v}_baseos_latest.qcow2"

              ['VMHOST1', 'VMHOST2'].each { hostParam ->
                def host = params[hostParam]
                echo "Syncing ubuntu${v} qcow to ${host}"

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
            def retentionDays = 7
            // One timestamp per pipeline run – same across versions and hosts
            def ts = new Date().format("yyyy-MM-dd'T'HHmmss", TimeZone.getTimeZone('UTC'))

            IMAGE_VERSIONS.each { v ->
              def currentName  = "${params.QCOW_REMOTE_PATH}/boot/ubuntu${v}_baseos.qcow2"
              def previousName = "${params.QCOW_REMOTE_PATH}/boot/ubuntu${v}_baseos_previous.qcow2"
              def latestName   = "${params.QCOW_REMOTE_PATH}/boot/ubuntu${v}_baseos_latest.qcow2"
              def archiveDir   = "${params.QCOW_REMOTE_PATH}/archive"
              def archiveName  = "${archiveDir}/ubuntu${v}_baseos_${ts}.qcow2"

              ['VMHOST1', 'VMHOST2'].each { hostParam ->
                def host = params[hostParam]
                echo "Activating ubuntu${v} image on ${host}"

                sh """
                  set -eu
                  mkdir -p ssh_keys
                  # write Jenkins SSH key from env var to file
                  cat "\$JENKINS_USER_KEY" > ssh_keys/id_ed25519_jenkins
                  chmod 600 ssh_keys/id_ed25519_jenkins
                  sed -i -e '/^\\\$/d' ssh_keys/id_ed25519_jenkins

                  ssh -o StrictHostKeyChecking=no -i ssh_keys/id_ed25519_jenkins \\
                    "\$JENKINS_USER_NAME@${host}" \\
                    "set -e
                     sudo mkdir -p '${archiveDir}'

                     # Move current to previous if it exists (for quick rollback)
                     if [ -f '${currentName}' ]; then
                       sudo mv '${currentName}' '${previousName}' || true
                     fi

                     # Copy latest to current (this is what VMs will use)
                     sudo cp -p '${latestName}' '${currentName}'

                     # Save a timestamped archive of the latest image
                     sudo cp -p '${latestName}' '${archiveName}'

                     # Prune archives older than ${retentionDays} days
                     sudo find '${archiveDir}' -name 'ubuntu${v}_baseos_*.qcow2' -type f -mtime +${retentionDays} -print -delete
                    "
                """
              }
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
