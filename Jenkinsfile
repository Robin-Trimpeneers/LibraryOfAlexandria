pipeline {
    agent any
    
    tools {
        maven 'Maven-3.9.4'
    }
    
    environment {
        DOCKER_REPO = 'robintrimpeneerspxl/librarydb'
        SERVER_IP = '192.168.129.139'
        DEPLOY_USER = credentials('deploy-user-credentials')
        
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
                    sh './mvnw clean test -Dspring.profiles.active=test'
                }
            }
            post {
                always {
                    junit testResultsPattern: 'Backend/target/surefire-reports/*.xml'
                }
            }
        }
        
        stage('Build') {
            steps {
                dir('Backend') {
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
                    
                    // Create .env file with Jenkins credentials
                    def envContent = """# Database Configuration
SPRING_DATASOURCE_USERNAME=${env.DB_CREDENTIALS_USR}
SPRING_DATASOURCE_PASSWORD=${env.DB_CREDENTIALS_PSW}
MYSQL_USER=${env.DB_CREDENTIALS_USR}
MYSQL_PASSWORD=${env.DB_CREDENTIALS_PSW}
MYSQL_ROOT_PASSWORD=${env.DB_CREDENTIALS_PSW}

# JWT Configuration
JWT_SECRET=${env.JWT_SECRET}

# Google Books API
GOOGLE_API_KEY=${env.GOOGLE_API_KEY}

# Application Profile
SPRING_PROFILES_ACTIVE=${params.ENVIRONMENT}
"""
                    writeFile file: '.env', text: envContent
                    
                    sshagent(['ssh-key-credentials']) {
                        sh """
                            # Create deployment directory
                            ssh -o StrictHostKeyChecking=no ${env.DEPLOY_USER_USR}@${env.SERVER_IP} '
                                sudo mkdir -p ${deployPath}
                                sudo chown ${env.DEPLOY_USER_USR}:${env.DEPLOY_USER_USR} ${deployPath}
                            '
                            
                            # Copy files
                            scp -o StrictHostKeyChecking=no ${composeFile} ${env.DEPLOY_USER_USR}@${env.SERVER_IP}:${deployPath}/
                            scp -o StrictHostKeyChecking=no .env ${env.DEPLOY_USER_USR}@${env.SERVER_IP}:${deployPath}/
                            scp -o StrictHostKeyChecking=no nginx.conf ${env.DEPLOY_USER_USR}@${env.SERVER_IP}:${deployPath}/
                            scp -o StrictHostKeyChecking=no init.sql ${env.DEPLOY_USER_USR}@${env.SERVER_IP}:${deployPath}/
                            scp -r -o StrictHostKeyChecking=no Frontend ${env.DEPLOY_USER_USR}@${env.SERVER_IP}:${deployPath}/
                            
                            # Deploy
                            ssh -o StrictHostKeyChecking=no ${env.DEPLOY_USER_USR}@${env.SERVER_IP} '
                                cd ${deployPath}
                                
                                # Update image tag in compose file
                                sed -i "s|image: robintrimpeneerspxl/librarydb.*|image: robintrimpeneerspxl/librarydb:${env.DOCKER_TAG}|g" ${composeFile}
                                
                                # Stop and start containers
                                docker-compose -f ${composeFile} down || true
                                docker-compose -f ${composeFile} up -d
                                
                                # Wait and check health
                                sleep 30
                                curl -f http://localhost:8080 || exit 1
                            '
                        """
                    }
                }
            }
        }
    }
    
    post {
        always {
            cleanWs()
        }
    }
}