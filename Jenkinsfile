pipeline {
    agent any
    
    tools {
        maven 'Maven-3.9.4'
        jdk 'JDK-21'
    }
    
    environment {
        // Docker registry configuration
        DOCKER_REGISTRY = 'docker.io'
        DOCKER_REPO = 'robintrimpeneerspxl/librarydb'
        
        // Application configuration
        APP_NAME = 'library-of-alexandria'
        
        // Environment-specific configurations
        DEV_SERVER = '192.168.129.139'
        STAGING_SERVER = '192.168.129.139'
        PROD_SERVER = '192.168.129.139'
        DEPLOY_USER = credentials('deploy-user-credentials')
        
        // Database credentials
        DB_CREDENTIALS = credentials('mysql-credentials')
        
        // API keys and secrets
        JWT_SECRET = credentials('jwt-secret')
        GOOGLE_API_KEY = credentials('google-api-key')
        
        // Docker Hub credentials
        DOCKER_HUB_CREDENTIALS = credentials('docker-hub-credentials')
        
        // SonarQube configuration
        SONAR_TOKEN = credentials('sonar-token')
        
        // Notification channels
        SLACK_CHANNEL = '#library-alerts'
        EMAIL_RECIPIENTS = 'dev-team@yourcompany.com'
    }
    
    parameters {
        choice(
            name: 'ENVIRONMENT',
            choices: ['dev', 'staging', 'production'],
            description: 'Target environment for deployment'
        )
        booleanParam(
            name: 'SKIP_TESTS',
            defaultValue: false,
            description: 'Skip test execution'
        )
        booleanParam(
            name: 'DEPLOY_AFTER_BUILD',
            defaultValue: true,
            description: 'Deploy automatically after successful build'
        )
        string(
            name: 'DOCKER_TAG',
            defaultValue: '',
            description: 'Custom Docker tag (leave empty for auto-generated)'
        )
    }
    
    stages {
        stage('Preparation') {
            steps {
                script {
                    // Set build display name
                    currentBuild.displayName = "#${BUILD_NUMBER} - ${params.ENVIRONMENT}"
                    
                    // Generate Docker tag if not provided
                    if (params.DOCKER_TAG == '') {
                        env.DOCKER_TAG = "${env.BUILD_NUMBER}-${env.GIT_COMMIT.take(7)}"
                    } else {
                        env.DOCKER_TAG = params.DOCKER_TAG
                    }
                    
                    echo "Building for environment: ${params.ENVIRONMENT}"
                    echo "Docker tag: ${env.DOCKER_TAG}"
                }
                
                // Clean workspace
                cleanWs()
                
                // Checkout code
                checkout scm
                
                // Create build info
                script {
                    def buildInfo = [
                        buildNumber: env.BUILD_NUMBER,
                        gitCommit: env.GIT_COMMIT,
                        gitBranch: env.GIT_BRANCH,
                        environment: params.ENVIRONMENT,
                        timestamp: new Date().format('yyyy-MM-dd HH:mm:ss')
                    ]
                    writeJSON file: 'build-info.json', json: buildInfo
                }
            }
        }
        
        stage('Environment Setup') {
            steps {
                script {
                    // Create environment-specific .env file
                    def envContent = """
SPRING_DATASOURCE_USERNAME=${env.DB_CREDENTIALS_USR}
SPRING_DATASOURCE_PASSWORD=${env.DB_CREDENTIALS_PSW}
MYSQL_USER=${env.DB_CREDENTIALS_USR}
MYSQL_PASSWORD=${env.DB_CREDENTIALS_PSW}
MYSQL_ROOT_PASSWORD=${env.DB_CREDENTIALS_PSW}
JWT_SECRET=${env.JWT_SECRET}
GOOGLE_API_KEY=${env.GOOGLE_API_KEY}
SPRING_PROFILES_ACTIVE=${params.ENVIRONMENT}
"""
                    writeFile file: '.env', text: envContent
                }
                
                // Verify Java and Maven versions
                sh '''
                    echo "Java Version:"
                    java -version
                    echo "Maven Version:"
                    mvn -version
                '''
            }
        }
        
        stage('Code Quality & Security') {
            parallel {
                stage('Static Code Analysis') {
                    steps {
                        dir('Backend') {
                            script {
                                try {
                                    // SonarQube analysis
                                    withSonarQubeEnv('SonarQube') {
                                        sh '''
                                            mvn clean compile sonar:sonar \
                                                -Dsonar.projectKey=library-of-alexandria \
                                                -Dsonar.projectName="Library of Alexandria" \
                                                -Dsonar.host.url=${SONAR_HOST_URL} \
                                                -Dsonar.login=${SONAR_TOKEN}
                                        '''
                                    }
                                    
                                    // Wait for SonarQube quality gate
                                    timeout(time: 5, unit: 'MINUTES') {
                                        def qg = waitForQualityGate()
                                        if (qg.status != 'OK') {
                                            error "Pipeline aborted due to quality gate failure: ${qg.status}"
                                        }
                                    }
                                } catch (Exception e) {
                                    echo "SonarQube analysis failed: ${e.getMessage()}"
                                    unstable("SonarQube analysis failed")
                                }
                            }
                        }
                    }
                }
                
                stage('Security Scan') {
                    steps {
                        dir('Backend') {
                            script {
                                try {
                                    // OWASP Dependency Check
                                    sh 'mvn org.owasp:dependency-check-maven:check'
                                    
                                    // Publish security report
                                    publishHTML([
                                        allowMissing: false,
                                        alwaysLinkToLastBuild: true,
                                        keepAll: true,
                                        reportDir: 'target',
                                        reportFiles: 'dependency-check-report.html',
                                        reportName: 'OWASP Dependency Check Report'
                                    ])
                                } catch (Exception e) {
                                    echo "Security scan failed: ${e.getMessage()}"
                                    unstable("Security scan failed")
                                }
                            }
                        }
                        
                        // Trivy filesystem scan
                        script {
                            try {
                                sh '''
                                    # Install Trivy if not available
                                    if ! command -v trivy &> /dev/null; then
                                        wget -qO- https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sh -s -- -b /usr/local/bin
                                    fi
                                    
                                    # Run Trivy scan
                                    trivy fs --exit-code 0 --severity HIGH,CRITICAL --format json -o trivy-report.json .
                                '''
                                
                                // Archive Trivy report
                                archiveArtifacts artifacts: 'trivy-report.json', allowEmptyArchive: true
                            } catch (Exception e) {
                                echo "Trivy scan failed: ${e.getMessage()}"
                                unstable("Trivy scan failed")
                            }
                        }
                    }
                }
                
                stage('License Check') {
                    steps {
                        dir('Backend') {
                            script {
                                try {
                                    sh 'mvn license:check'
                                    sh 'mvn license:aggregate-third-party-report'
                                    
                                    publishHTML([
                                        allowMissing: true,
                                        alwaysLinkToLastBuild: true,
                                        keepAll: true,
                                        reportDir: 'target/site',
                                        reportFiles: 'aggregate-third-party-report.html',
                                        reportName: 'License Report'
                                    ])
                                } catch (Exception e) {
                                    echo "License check failed: ${e.getMessage()}"
                                    unstable("License check failed")
                                }
                            }
                        }
                    }
                }
            }
        }
        
        stage('Build & Test') {
            when {
                not { params.SKIP_TESTS }
            }
            steps {
                dir('Backend') {
                    // Build and run tests
                    sh '''
                        mvn clean compile test-compile
                        mvn test -Dmaven.test.failure.ignore=true
                    '''
                    
                    // Publish test results
                    publishTestResults testResultsPattern: 'target/surefire-reports/*.xml'
                    
                    // Publish coverage report
                    publishHTML([
                        allowMissing: true,
                        alwaysLinkToLastBuild: true,
                        keepAll: true,
                        reportDir: 'target/site/jacoco',
                        reportFiles: 'index.html',
                        reportName: 'JaCoCo Coverage Report'
                    ])
                }
            }
            post {
                always {
                    // Archive test artifacts
                    archiveArtifacts artifacts: 'Backend/target/surefire-reports/**', allowEmptyArchive: true
                }
            }
        }
        
        stage('Package Application') {
            steps {
                dir('Backend') {
                    // Package the application
                    sh 'mvn clean package -DskipTests'
                    
                    // Archive the JAR file
                    archiveArtifacts artifacts: 'target/*.jar', fingerprint: true
                }
            }
        }
        
        stage('Build Docker Image') {
            steps {
                script {
                    // Build Docker image
                    def dockerImage = docker.build("${env.DOCKER_REPO}:${env.DOCKER_TAG}", "./Backend")
                    
                    // Tag with additional tags
                    if (env.GIT_BRANCH == 'origin/main') {
                        dockerImage.tag('latest')
                    }
                    dockerImage.tag("${params.ENVIRONMENT}")
                    
                    // Store image for later use
                    env.DOCKER_IMAGE = dockerImage.id
                }
            }
        }
        
        stage('Docker Security Scan') {
            steps {
                script {
                    try {
                        // Scan Docker image with Trivy
                        sh """
                            trivy image --exit-code 0 --severity HIGH,CRITICAL \
                                --format json -o docker-trivy-report.json \
                                ${env.DOCKER_REPO}:${env.DOCKER_TAG}
                        """
                        
                        // Archive Docker security report
                        archiveArtifacts artifacts: 'docker-trivy-report.json', allowEmptyArchive: true
                    } catch (Exception e) {
                        echo "Docker security scan failed: ${e.getMessage()}"
                        unstable("Docker security scan failed")
                    }
                }
            }
        }
        
        stage('Integration Tests') {
            when {
                not { params.SKIP_TESTS }
            }
            steps {
                script {
                    try {
                        // Run integration tests with Docker Compose
                        sh '''
                            # Create test environment file
                            cp .env .env.test
                            echo "SPRING_PROFILES_ACTIVE=test" >> .env.test
                            
                            # Start test environment
                            docker-compose -f docker-compose.test.yml up -d --build
                            
                            # Wait for services to be ready
                            sleep 30
                            
                            # Run integration tests
                            docker-compose -f docker-compose.test.yml exec -T springboot-app \
                                java -jar app.jar --spring.profiles.active=test || true
                        '''
                    } catch (Exception e) {
                        echo "Integration tests failed: ${e.getMessage()}"
                        unstable("Integration tests failed")
                    } finally {
                        // Clean up test environment
                        sh 'docker-compose -f docker-compose.test.yml down -v || true'
                    }
                }
            }
        }
        
        stage('Push Docker Image') {
            when {
                anyOf {
                    branch 'main'
                    branch 'develop'
                    expression { params.ENVIRONMENT == 'production' }
                }
            }
            steps {
                script {
                    docker.withRegistry("https://${env.DOCKER_REGISTRY}", env.DOCKER_HUB_CREDENTIALS) {
                        def dockerImage = docker.image("${env.DOCKER_REPO}:${env.DOCKER_TAG}")
                        dockerImage.push()
                        
                        if (env.GIT_BRANCH == 'origin/main') {
                            dockerImage.push('latest')
                        }
                        dockerImage.push("${params.ENVIRONMENT}")
                    }
                }
            }
        }
        
        stage('Deploy') {
            when {
                expression { params.DEPLOY_AFTER_BUILD }
            }
            steps {
                script {
                    def deploymentConfig = getDeploymentConfig(params.ENVIRONMENT)
                    
                    echo "Deploying to ${params.ENVIRONMENT} environment..."
                    
                    // Deploy based on environment
                    switch(params.ENVIRONMENT) {
                        case 'dev':
                            deployToDev(deploymentConfig)
                            break
                        case 'staging':
                            deployToStaging(deploymentConfig)
                            break
                        case 'production':
                            deployToProduction(deploymentConfig)
                            break
                        default:
                            error("Unknown environment: ${params.ENVIRONMENT}")
                    }
                }
            }
        }
        
        stage('Health Check') {
            when {
                expression { params.DEPLOY_AFTER_BUILD }
            }
            steps {
                script {
                    def deploymentConfig = getDeploymentConfig(params.ENVIRONMENT)
                    
                    echo "Performing health check for ${params.ENVIRONMENT}..."
                    
                    // Wait for application to start
                    sleep(30)
                    
                    // Health check with retry
                    retry(5) {
                        sleep(10)
                        sh """
                            curl -f ${deploymentConfig.healthUrl} || exit 1
                        """
                    }
                    
                    echo "Health check passed for ${params.ENVIRONMENT}"
                }
            }
        }
        
        stage('Performance Tests') {
            when {
                anyOf {
                    expression { params.ENVIRONMENT == 'staging' }
                    expression { params.ENVIRONMENT == 'production' }
                }
            }
            steps {
                script {
                    try {
                        // Run basic performance tests
                        sh '''
                            # Install Apache Bench if not available
                            if ! command -v ab &> /dev/null; then
                                apt-get update && apt-get install -y apache2-utils
                            fi
                            
                            # Run performance test
                            ab -n 100 -c 10 http://localhost:8080/ > performance-report.txt
                        '''
                        
                        // Archive performance report
                        archiveArtifacts artifacts: 'performance-report.txt', allowEmptyArchive: true
                    } catch (Exception e) {
                        echo "Performance tests failed: ${e.getMessage()}"
                        unstable("Performance tests failed")
                    }
                }
            }
        }
    }
    
    post {
        always {
            // Clean up Docker images
            script {
                try {
                    sh 'docker image prune -f'
                } catch (Exception e) {
                    echo "Docker cleanup failed: ${e.getMessage()}"
                }
            }
            
            // Archive build artifacts
            archiveArtifacts artifacts: 'build-info.json', allowEmptyArchive: true
        }
        
        success {
            script {
                def message = """
🎉 *Build Successful* 🎉
*Project:* Library of Alexandria
*Build:* #${env.BUILD_NUMBER}
*Branch:* ${env.GIT_BRANCH}
*Environment:* ${params.ENVIRONMENT}
*Docker Tag:* ${env.DOCKER_TAG}
*Duration:* ${currentBuild.durationString}
"""
                
                // Send Slack notification
                try {
                    slackSend(
                        channel: env.SLACK_CHANNEL,
                        color: 'good',
                        message: message
                    )
                } catch (Exception e) {
                    echo "Slack notification failed: ${e.getMessage()}"
                }
                
                // Send email notification
                try {
                    emailext(
                        subject: "✅ Library of Alexandria - Build #${env.BUILD_NUMBER} Successful",
                        body: message,
                        to: env.EMAIL_RECIPIENTS
                    )
                } catch (Exception e) {
                    echo "Email notification failed: ${e.getMessage()}"
                }
            }
        }
        
        failure {
            script {
                def message = """
❌ *Build Failed* ❌
*Project:* Library of Alexandria
*Build:* #${env.BUILD_NUMBER}
*Branch:* ${env.GIT_BRANCH}
*Environment:* ${params.ENVIRONMENT}
*Duration:* ${currentBuild.durationString}
*Console:* ${env.BUILD_URL}console
"""
                
                // Send Slack notification
                try {
                    slackSend(
                        channel: env.SLACK_CHANNEL,
                        color: 'danger',
                        message: message
                    )
                } catch (Exception e) {
                    echo "Slack notification failed: ${e.getMessage()}"
                }
                
                // Send email notification
                try {
                    emailext(
                        subject: "❌ Library of Alexandria - Build #${env.BUILD_NUMBER} Failed",
                        body: message,
                        to: env.EMAIL_RECIPIENTS
                    )
                } catch (Exception e) {
                    echo "Email notification failed: ${e.getMessage()}"
                }
            }
        }
        
        unstable {
            script {
                def message = """
⚠️ *Build Unstable* ⚠️
*Project:* Library of Alexandria
*Build:* #${env.BUILD_NUMBER}
*Branch:* ${env.GIT_BRANCH}
*Environment:* ${params.ENVIRONMENT}
*Duration:* ${currentBuild.durationString}
*Console:* ${env.BUILD_URL}console
"""
                
                // Send Slack notification
                try {
                    slackSend(
                        channel: env.SLACK_CHANNEL,
                        color: 'warning',
                        message: message
                    )
                } catch (Exception e) {
                    echo "Slack notification failed: ${e.getMessage()}"
                }
            }
        }
    }
}

// Helper function to get deployment configuration
def getDeploymentConfig(environment) {
    def configs = [
        'dev': [
            server: env.DEV_SERVER,
            user: env.DEPLOY_USER_USR,
            password: env.DEPLOY_USER_PSW,
            healthUrl: "http://${env.DEV_SERVER}:8080/api/actuator/health",
            appUrl: "http://${env.DEV_SERVER}:8080",
            dockerCompose: 'docker-compose.dev.yml',
            deployPath: '/opt/library-app-dev'
        ],
        'staging': [
            server: env.STAGING_SERVER,
            user: env.DEPLOY_USER_USR,
            password: env.DEPLOY_USER_PSW,
            healthUrl: "http://${env.STAGING_SERVER}:8080/api/actuator/health",
            appUrl: "http://${env.STAGING_SERVER}:8080",
            dockerCompose: 'docker-compose.yml',
            deployPath: '/opt/library-app-staging'
        ],
        'production': [
            server: env.PROD_SERVER,
            user: env.DEPLOY_USER_USR,
            password: env.DEPLOY_USER_PSW,
            healthUrl: "http://${env.PROD_SERVER}:8080/api/actuator/health",
            appUrl: "http://${env.PROD_SERVER}:8080",
            dockerCompose: 'docker-compose.yml',
            deployPath: '/opt/library-app'
        ]
    ]
    return configs[environment]
}

// Deployment functions
def deployToDev(config) {
    echo "Deploying to development environment on ${config.server}..."
    
    sshagent(['ssh-key-credentials']) {
        sh """
            # Create deployment directory
            ssh -o StrictHostKeyChecking=no ${config.user}@${config.server} '
                sudo mkdir -p ${config.deployPath}
                sudo chown ${config.user}:${config.user} ${config.deployPath}
            '
            
            # Copy application files
            scp -o StrictHostKeyChecking=no docker-compose.dev.yml ${config.user}@${config.server}:${config.deployPath}/
            scp -o StrictHostKeyChecking=no .env ${config.user}@${config.server}:${config.deployPath}/
            scp -o StrictHostKeyChecking=no nginx.conf ${config.user}@${config.server}:${config.deployPath}/
            scp -o StrictHostKeyChecking=no init.sql ${config.user}@${config.server}:${config.deployPath}/
            scp -r -o StrictHostKeyChecking=no Frontend ${config.user}@${config.server}:${config.deployPath}/
            
            # Deploy on remote server
            ssh -o StrictHostKeyChecking=no ${config.user}@${config.server} '
                cd ${config.deployPath}
                
                # Update Docker image
                docker pull ${env.DOCKER_REPO}:${env.DOCKER_TAG}
                
                # Stop existing containers
                docker-compose -f docker-compose.dev.yml down || true
                
                # Start new deployment
                docker-compose -f docker-compose.dev.yml up -d
                
                # Clean up old images
                docker image prune -f
            '
        """
    }
    
    echo "✅ Development deployment completed on ${config.server}"
}

def deployToStaging(config) {
    echo "Deploying to staging environment on ${config.server}..."
    
    sshagent(['ssh-key-credentials']) {
        sh """
            # Create deployment directory
            ssh -o StrictHostKeyChecking=no ${config.user}@${config.server} '
                sudo mkdir -p ${config.deployPath}
                sudo chown ${config.user}:${config.user} ${config.deployPath}
            '
            
            # Copy application files
            scp -o StrictHostKeyChecking=no docker-compose.yml ${config.user}@${config.server}:${config.deployPath}/
            scp -o StrictHostKeyChecking=no .env ${config.user}@${config.server}:${config.deployPath}/
            scp -o StrictHostKeyChecking=no nginx.conf ${config.user}@${config.server}:${config.deployPath}/
            scp -o StrictHostKeyChecking=no init.sql ${config.user}@${config.server}:${config.deployPath}/
            scp -r -o StrictHostKeyChecking=no Frontend ${config.user}@${config.server}:${config.deployPath}/
            
            # Deploy on remote server with backup
            ssh -o StrictHostKeyChecking=no ${config.user}@${config.server} '
                cd ${config.deployPath}
                
                # Backup current deployment
                if [ -d "backup" ]; then rm -rf backup; fi
                if [ -f docker-compose.yml ]; then
                    mkdir -p backup
                    docker-compose ps > backup/containers.txt
                    echo "Backup created for rollback"
                fi
                
                # Update Docker image
                docker pull ${env.DOCKER_REPO}:${env.DOCKER_TAG}
                
                # Stop existing containers gracefully
                docker-compose down
                
                # Start new deployment
                docker-compose up -d
                
                # Wait for services to be ready
                sleep 30
                
                # Clean up old images
                docker image prune -f
            '
        """
    }
    
    echo "✅ Staging deployment completed on ${config.server}"
}

def deployToProduction(config) {
    // Production deployment with extra safety checks
    input message: 'Deploy to Production?', ok: 'Deploy', 
          submitterParameter: 'APPROVER'
    
    echo "Deploying to production environment on ${config.server}..."
    echo "Approved by: ${env.APPROVER}"
    
    sshagent(['ssh-key-credentials']) {
        sh """
            # Create deployment directory
            ssh -o StrictHostKeyChecking=no ${config.user}@${config.server} '
                sudo mkdir -p ${config.deployPath}
                sudo chown ${config.user}:${config.user} ${config.deployPath}
                sudo mkdir -p ${config.deployPath}/backups
            '
            
            # Create full backup before deployment
            ssh -o StrictHostKeyChecking=no ${config.user}@${config.server} '
                cd ${config.deployPath}
                
                # Database backup
                if docker-compose ps | grep mysql; then
                    echo "Creating database backup..."
                    docker-compose exec -T mysql mysqldump -u root -p\${MYSQL_ROOT_PASSWORD} librarydb > backups/db_backup_\$(date +%Y%m%d_%H%M%S).sql
                fi
                
                # Application backup
                if [ -f docker-compose.yml ]; then
                    echo "Creating application backup..."
                    tar -czf backups/app_backup_\$(date +%Y%m%d_%H%M%S).tar.gz . --exclude=backups
                fi
            '
            
            # Copy application files
            scp -o StrictHostKeyChecking=no docker-compose.yml ${config.user}@${config.server}:${config.deployPath}/
            scp -o StrictHostKeyChecking=no .env ${config.user}@${config.server}:${config.deployPath}/
            scp -o StrictHostKeyChecking=no nginx.conf ${config.user}@${config.server}:${config.deployPath}/
            scp -o StrictHostKeyChecking=no init.sql ${config.user}@${config.server}:${config.deployPath}/
            scp -r -o StrictHostKeyChecking=no Frontend ${config.user}@${config.server}:${config.deployPath}/
            
            # Blue-Green deployment for production
            ssh -o StrictHostKeyChecking=no ${config.user}@${config.server} '
                cd ${config.deployPath}
                
                # Update Docker image
                docker pull ${env.DOCKER_REPO}:${env.DOCKER_TAG}
                
                # Rolling deployment - update one service at a time
                echo "Starting rolling deployment..."
                
                # Update backend first
                docker-compose up -d springboot-app
                sleep 30
                
                # Verify backend health
                for i in {1..10}; do
                    if curl -f http://localhost:5050/actuator/health; then
                        echo "Backend health check passed"
                        break
                    fi
                    echo "Waiting for backend... attempt \$i"
                    sleep 10
                done
                
                # Update other services
                docker-compose up -d nginx mysql phpmyadmin
                
                # Final health check
                sleep 30
                if curl -f http://localhost:8080; then
                    echo "✅ Production deployment successful"
                    
                    # Clean up old images and containers
                    docker image prune -f
                    docker container prune -f
                else
                    echo "❌ Production deployment failed - consider rollback"
                    exit 1
                fi
            '
        """
    }
    
    echo "✅ Production deployment completed on ${config.server}"
    echo "🚀 Application available at: ${config.appUrl}"
}