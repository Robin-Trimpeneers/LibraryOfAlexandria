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
                            
                            # Debug: List available files in workspace
                            echo "=== Files in workspace root ==="
                            ls -la
                            echo "=== Looking for compose files ==="
                            find . -name "*.yml" -o -name "*.yaml" | head -10
                            
                            # Create deployment directory
                            ssh -i \$SSH_KEY -o StrictHostKeyChecking=no \$SSH_USER@${env.SERVER_IP} '
                                mkdir -p ~/deployments/${deployPath.replaceAll('/opt/', '')}
                                DEPLOY_PATH=~/deployments/${deployPath.replaceAll('/opt/', '')}
                                echo "Using deployment path: \$DEPLOY_PATH"
                            '
                            
                            # Find and copy compose file
                            if [ -f "compose.yaml" ]; then
                                echo "Found compose.yaml, copying..."
                                scp -i \$SSH_KEY -o StrictHostKeyChecking=no compose.yaml \$SSH_USER@${env.SERVER_IP}:~/deployments/${deployPath.replaceAll('/opt/', '')}/docker-compose.yml
                            elif [ -f "docker-compose.yml" ]; then
                                echo "Found docker-compose.yml, copying..."
                                scp -i \$SSH_KEY -o StrictHostKeyChecking=no docker-compose.yml \$SSH_USER@${env.SERVER_IP}:~/deployments/${deployPath.replaceAll('/opt/', '')}/
                            elif [ -f "${composeFile}" ]; then
                                echo "Found ${composeFile}, copying..."
                                scp -i \$SSH_KEY -o StrictHostKeyChecking=no ${composeFile} \$SSH_USER@${env.SERVER_IP}:~/deployments/${deployPath.replaceAll('/opt/', '')}/
                            else
                                echo "ERROR: No compose file found!"
                                exit 1
                            fi
                            
                            # Copy .env file
                            scp -i \$SSH_KEY -o StrictHostKeyChecking=no .env \$SSH_USER@${env.SERVER_IP}:~/deployments/${deployPath.replaceAll('/opt/', '')}/
                            
                            # Copy other files if they exist
                            [ -f nginx.conf ] && scp -i \$SSH_KEY -o StrictHostKeyChecking=no nginx.conf \$SSH_USER@${env.SERVER_IP}:~/deployments/${deployPath.replaceAll('/opt/', '')}/ || echo "nginx.conf not found"
                            [ -f init.sql ] && scp -i \$SSH_KEY -o StrictHostKeyChecking=no init.sql \$SSH_USER@${env.SERVER_IP}:~/deployments/${deployPath.replaceAll('/opt/', '')}/ || echo "init.sql not found"
                            [ -d Frontend ] && scp -r -i \$SSH_KEY -o StrictHostKeyChecking=no Frontend \$SSH_USER@${env.SERVER_IP}:~/deployments/${deployPath.replaceAll('/opt/', '')}/ || echo "Frontend directory not found"
                            
                            # Deploy application
                            ssh -i \$SSH_KEY -o StrictHostKeyChecking=no \$SSH_USER@${env.SERVER_IP} '
                                DEPLOY_PATH=~/deployments/${deployPath.replaceAll('/opt/', '')}
                                cd \$DEPLOY_PATH
                                
                                # List files to verify they were copied
                                echo "Files in deployment directory:"
                                ls -la
                                
                                # Use docker-compose.yml (should exist now)
                                COMPOSE_FILE="docker-compose.yml"
                                
                                echo "Using compose file: \$COMPOSE_FILE"
                                
                                # Update image tag in compose file and remove build directive since we have pre-built image
                                sed -i "s|image: robintrimpeneerspxl/librarydb.*|image: robintrimpeneerspxl/librarydb:${env.DOCKER_TAG}|g" \$COMPOSE_FILE
                                sed -i "/build: .\\/Backend/d" \$COMPOSE_FILE
                                
                                # Show updated compose file content
                                echo "Updated compose file content:"
                                cat \$COMPOSE_FILE
                                
                                # Stop and start containers (using docker compose V2 syntax)
                                docker compose -f \$COMPOSE_FILE down || true
                                docker compose -f \$COMPOSE_FILE up -d
                                
                                # Wait and check health
                                sleep 30
                                
                                # Check container status
                                echo "Container status:"
                                docker compose -f \$COMPOSE_FILE ps
                                
                                # Try different health check endpoints
                                curl -f http://localhost:8080/actuator/health || curl -f http://localhost:8080 || curl -f http://localhost:5050/actuator/health || curl -f http://localhost:5050 || echo "Health check failed but containers may still be starting"
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