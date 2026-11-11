
pipeline {
    agent any

    environment {
        AWS_REGION = 'ap-southeast-2'
        FRONTEND_REPO = 'booknest-frontend'
        BACKEND_REPO = 'booknest-backend'
    }

    stages {
        stage('Checkout') {
            steps {
                checkout scm
                script {
                    env.IMAGE_TAG = sh(
                        script: 'git rev-parse --short=12 HEAD',
                        returnStdout: true
                    ).trim()
                }
            }
        }

        stage('Build Images') {
            steps {
                sh '''
                    docker build \
                      -t ${FRONTEND_REPO}:${IMAGE_TAG} \
                      ./booknest/frontend/frontend

                    docker build \
                      -t ${BACKEND_REPO}:${IMAGE_TAG} \
                      ./booknest/backend
                '''
            }
        }

        stage('Push to ECR') {
            steps {
                sh '''
                    ACCOUNT_ID=$(aws sts get-caller-identity \
                      --query Account --output text)

                    REGISTRY="${ACCOUNT_ID}.dkr.ecr.${AWS_REGION}.amazonaws.com"

                    aws ecr get-login-password --region ${AWS_REGION} |
                      docker login --username AWS --password-stdin ${REGISTRY}

                    docker tag ${FRONTEND_REPO}:${IMAGE_TAG} \
                      ${REGISTRY}/${FRONTEND_REPO}:${IMAGE_TAG}

                    docker tag ${BACKEND_REPO}:${IMAGE_TAG} \
                      ${REGISTRY}/${BACKEND_REPO}:${IMAGE_TAG}

                    docker push ${REGISTRY}/${FRONTEND_REPO}:${IMAGE_TAG}
                    docker push ${REGISTRY}/${BACKEND_REPO}:${IMAGE_TAG}
                '''
            }
        }
    }

    post {
        success {
            echo 'Both application images were pushed successfully to ECR.'
        }
        failure {
            echo 'Pipeline failed. Check the stage logs.'
        }
        always {
            sh '''
                docker image prune -f
            '''
        }
    }
}
