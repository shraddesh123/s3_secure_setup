pipeline {
    agent any

    environment {
        TF_VAR_vpc_cidr            = '10.0.0.0/16'
        TF_VAR_bucketname          = 'secure-s3-bucket'
        TF_VAR_private_subnet_cidr = '10.0.2.0/24'
        TF_VAR_public_subnet_cidr  = '10.0.1.0/24'
    }

    stages {
        stage('Checkout Code') {
            steps {
                git url: 'https://github.com/shraddesh123/s3_secure_setup.git', branch: 'main'
            }
        }

        stage('Terraform Init') {
            steps {
                sh 'terraform init'
            }
        }

        stage('Terraform Validate') {
            steps {
                sh 'terraform validate'
            }
        }

        stage('Terraform Plan') {
            steps {
                sh 'terraform plan'
            }
        }

        stage('Terraform Apply') {
            steps {
                sh 'terraform apply -auto-approve'
            }
        }

        stage('Terraform Output') {
            steps {
                sh 'terraform output'
            }
        }
    }

    post {
        always {
            echo "Terraform provisioning complete."
        }
    }
}
