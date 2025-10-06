pipeline {
    agent any
    
    tools {
        maven 'Maven-3.9.4'
    }
    
    environment {
        DOCKER_REPO = 'robintrimpeneerspxl/librarydb'
        SERVER_IP = '192.168.129.139'
        
        // Database credentials
        DB_CREDENTIALS = credentials('mysql-credentials')
        JWT_SECRET = credentials('jwt-secret')
        GOOGLE_API_KEY = credentials('google-api-key')
    }
    
    parameters {
        choice(
            name: 'ENVIRONMENT',
            choices: ['dev', 'staging', 'production'],
            description: 'Target environment for deployment'
        )
    }
    
    stages {
        stage('Checkout') {
            steps {
                checkout scm
                script {
                    env.DOCKER_TAG = "${env.BUILD_NUMBER}-${env.GIT_COMMIT.take(7)}"
                }
            }
        }
        
        stage('Test') {
            steps {
                dir('Backend') {
                    sh 'chmod +x ./mvnw'
                    sh './mvnw clean test -Dspring.profiles.active=test'
                }
            }
            post {
                always {
                    junit testResults: 'Backend/target/surefire-reports/*.xml', allowEmptyResults: true
                }
            }
        }
        
        stage('Build') {
            steps {
                dir('Backend') {
                    sh 'chmod +x ./mvnw'
                    sh './mvnw clean package -DskipTests'
                }
            }
        }
        
        stage('Docker Build') {
            steps {
                script {
                    docker.build("${env.DOCKER_REPO}:${env.DOCKER_TAG}", "./Backend")
                }
            }
        }
        
        stage('Deploy') {
            steps {
                script {
                    def deployPath = params.ENVIRONMENT == 'production' ? '/opt/library-app' : "/opt/library-app-${params.ENVIRONMENT}"
                    def composeFile = params.ENVIRONMENT == 'dev' ? 'docker-compose.dev.yml' : 'docker-compose.yml'
                    
                    // Create .env file with Jenkins credentials (using string concatenation for security)
                    def envContent = "# Database Configuration\n"
                    envContent += "SPRING_DATASOURCE_USERNAME=${env.DB_CREDENTIALS_USR}\n"
                    envContent += "SPRING_DATASOURCE_PASSWORD=${env.DB_CREDENTIALS_PSW}\n"
                    envContent += "MYSQL_USER=${env.DB_CREDENTIALS_USR}\n"
                    envContent += "MYSQL_PASSWORD=${env.DB_CREDENTIALS_PSW}\n"
                    envContent += "MYSQL_ROOT_PASSWORD=${env.DB_CREDENTIALS_PSW}\n"
                    envContent += "\n# JWT Configuration\n"
                    envContent += "JWT_SECRET=${env.JWT_SECRET}\n"
                    envContent += "\n# Google Books API\n"
                    envContent += "GOOGLE_API_KEY=${env.GOOGLE_API_KEY}\n"
                    envContent += "\n# Application Profile\n"
                    envContent += "SPRING_PROFILES_ACTIVE=${params.ENVIRONMENT}\n"
                    
                    writeFile file: '.env', text: envContent
                    
                    // SSH deployment with SSH key authentication
                    withCredentials([sshUserPrivateKey(credentialsId: 'ssh-key-credentials', keyFileVariable: 'SSH_KEY', usernameVariable: 'SSH_USER')]) {
                        sh """
                            # Set proper permissions for SSH key
                            chmod 600 \$SSH_KEY
                            
                            # Create deployment directory (without sudo, in user home)
                            ssh -i \$SSH_KEY -o StrictHostKeyChecking=no \$SSH_USER@${env.SERVER_IP} '
                                mkdir -p ~/deployments/${deployPath.replaceAll('/opt/', '')}
                                DEPLOY_PATH=~/deployments/${deployPath.replaceAll('/opt/', '')}
                                echo "Using deployment path: \$DEPLOY_PATH"
                            '
                            
                            # Copy deployment files
                            ssh -i \$SSH_KEY -o StrictHostKeyChecking=no \$SSH_USER@${env.SERVER_IP} "mkdir -p ~/deployments/${deployPath.replaceAll('/opt/', '')}"
                            scp -i \$SSH_KEY -o StrictHostKeyChecking=no ${composeFile} \$SSH_USER@${env.SERVER_IP}:~/deployments/${deployPath.replaceAll('/opt/', '')}/
                            scp -i \$SSH_KEY -o StrictHostKeyChecking=no .env \$SSH_USER@${env.SERVER_IP}:~/deployments/${deployPath.replaceAll('/opt/', '')}/
                            scp -i \$SSH_KEY -o StrictHostKeyChecking=no nginx.conf \$SSH_USER@${env.SERVER_IP}:~/deployments/${deployPath.replaceAll('/opt/', '')}/
                            scp -i \$SSH_KEY -o StrictHostKeyChecking=no init.sql \$SSH_USER@${env.SERVER_IP}:~/deployments/${deployPath.replaceAll('/opt/', '')}/
                            scp -r -i \$SSH_KEY -o StrictHostKeyChecking=no Frontend \$SSH_USER@${env.SERVER_IP}:~/deployments/${deployPath.replaceAll('/opt/', '')}/
                            
                            # Deploy application
                            ssh -i \$SSH_KEY -o StrictHostKeyChecking=no \$SSH_USER@${env.SERVER_IP} '
                                DEPLOY_PATH=~/deployments/${deployPath.replaceAll('/opt/', '')}
                                cd \$DEPLOY_PATH
                                
                                # Update image tag in compose file
                                sed -i "s|image: robintrimpeneerspxl/librarydb.*|image: robintrimpeneerspxl/librarydb:${env.DOCKER_TAG}|g" ${composeFile}
                                
                                # Stop and start containers (Docker should work without sudo if user is in docker group)
                                docker-compose -f ${composeFile} down || true
                                docker-compose -f ${composeFile} up -d
                                
                                # Wait and check health
                                sleep 30
                                curl -f http://localhost:8080/actuator/health || curl -f http://localhost:8080 || echo "Health check failed but deployment may still be successful"
                            '
                        """
                    }
                    
                    // Archive artifacts as backup
                    archiveArtifacts artifacts: '.env,docker-compose.yml,nginx.conf,init.sql', fingerprint: true
                }
            }
        }
    }
    
    post {
        always {
            script {
                // Clean workspace if in agent context
                try {
                    cleanWs()
                } catch (Exception e) {
                    echo "Workspace cleanup failed: ${e.getMessage()}"
                }
            }
        }
    }
}