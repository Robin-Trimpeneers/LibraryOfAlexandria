# Jenkins Pipeline Configuration for Library of Alexandria

This document describes the Jenkins CI/CD pipeline setup for the Library of Alexandria project.

## 🚀 Pipeline Overview

The Jenkins pipeline provides comprehensive CI/CD automation with the following stages:

### **Pipeline Stages:**

1. **Preparation** - Workspace setup and build configuration
2. **Environment Setup** - Dynamic environment configuration
3. **Code Quality & Security** (Parallel)
   - Static Code Analysis (SonarQube)
   - Security Scanning (OWASP, Trivy)
   - License Compliance Check
4. **Build & Test** - Maven build and unit tests
5. **Package Application** - Create JAR artifact
6. **Build Docker Image** - Multi-stage Docker build
7. **Docker Security Scan** - Container vulnerability scanning
8. **Integration Tests** - Full stack testing with Docker Compose
9. **Push Docker Image** - Push to Docker registry
10. **Deploy** - Environment-specific deployment
11. **Health Check** - Post-deployment verification
12. **Performance Tests** - Load testing for staging/production

## 🛠️ Jenkins Setup Requirements

### **Required Plugins:**

```bash
# Core plugins
Pipeline
Docker Pipeline
Maven Integration
Git
Workspace Cleanup

# Quality & Security
SonarQube Scanner
OWASP Dependency-Check
HTML Publisher

# Notifications
Slack Notification
Email Extension (Extended E-mail Notification)

# Testing
JUnit
Jacoco
Performance

# Deployment
SSH Agent
Publish Over SSH
```

### **Global Tool Configuration:**

1. **Maven Configuration:**
   - Name: `Maven-3.9.4`
   - Version: 3.9.4 or latest
   - Install automatically: ✅

2. **JDK Configuration:**
   - Name: `JDK-21`
   - Version: Eclipse Temurin 21
   - Install automatically: ✅

3. **Docker:**
   - Ensure Docker is installed on Jenkins agents
   - Docker daemon must be accessible

## 🔐 Required Credentials

Configure these credentials in Jenkins (Manage Jenkins → Credentials):

### **Database Credentials:**
```
ID: mysql-credentials
Type: Username with password
Username: appuser
Password: [your-mysql-password]
```

### **API Keys:**
```
ID: jwt-secret
Type: Secret text
Secret: [your-jwt-secret-key]

ID: google-api-key
Type: Secret text
Secret: [your-google-books-api-key]
```

### **Docker Registry:**
```
ID: docker-hub-credentials
Type: Username with password
Username: [your-dockerhub-username]
Password: [your-dockerhub-password]
```

### **Server Configurations:**
```
ID: deploy-user-credentials
Type: Username with password
Username: [ssh-username-for-192.168.129.139]
Password: [ssh-password-for-192.168.129.139]
Description: SSH credentials for deployment server

ID: ssh-key-credentials
Type: SSH Username with private key
Username: [ssh-username-for-192.168.129.139]
Private Key: [your-ssh-private-key]
Description: SSH key for secure deployment
```

### **Code Quality:**
```
ID: sonar-token
Type: Secret text
Secret: [your-sonarqube-token]
```

## 🌍 SonarQube Integration

### **SonarQube Server Setup:**

1. **Configure SonarQube Server:**
   - Go to: Manage Jenkins → Configure System
   - Add SonarQube server:
     - Name: `SonarQube`
     - Server URL: `http://your-sonarqube-server:9000`
     - Server authentication token: Use the `sonar-token` credential

2. **Create SonarQube Project:**
   - Project Key: `library-of-alexandria`
   - Project Name: `Library of Alexandria`

## 📧 Notification Setup

### **Slack Integration:**

1. **Install Slack Plugin**
2. **Configure Slack:**
   - Go to: Manage Jenkins → Configure System
   - Add Slack configuration:
     - Workspace: Your Slack workspace
     - Credential: Slack Bot Token
     - Default channel: `#library-alerts`

### **Email Configuration:**

1. **Configure Email in Jenkins:**
   - Go to: Manage Jenkins → Configure System
   - Configure Extended E-mail Notification:
     - SMTP server: Your SMTP server
     - Default Recipients: `dev-team@yourcompany.com`

## 🚀 Pipeline Usage

### **Triggering Builds:**

1. **Automatic Triggers:**
   - Push to `main` branch → Production pipeline
   - Push to `develop` branch → Staging pipeline
   - Pull requests → Test-only pipeline

2. **Manual Triggers:**
   - Use "Build with Parameters" for custom deployments
   - Select environment: `dev`, `staging`, or `production`
   - Optional: Skip tests or specify custom Docker tag

### **Pipeline Parameters:**

- **ENVIRONMENT**: Target deployment environment
- **SKIP_TESTS**: Skip test execution (for emergency deployments)
- **DEPLOY_AFTER_BUILD**: Automatic deployment after successful build
- **DOCKER_TAG**: Custom Docker image tag

## 🐳 Docker Compose Files for Testing

The pipeline uses different Docker Compose configurations:

### **docker-compose.test.yml** (Create this file):

```yaml
services:
  springboot-app:
    build: ./Backend
    environment:
      SPRING_PROFILES_ACTIVE: test
      SPRING_DATASOURCE_URL: jdbc:mysql://mysql-test:3306/librarydb_test
      SPRING_DATASOURCE_USERNAME: testuser
      SPRING_DATASOURCE_PASSWORD: testpass
      JWT_SECRET: test-secret-key
      GOOGLE_API_KEY: test-api-key
    depends_on:
      mysql-test:
        condition: service_healthy
    networks:
      - test-network

  mysql-test:
    image: mysql:8.0
    environment:
      MYSQL_DATABASE: librarydb_test
      MYSQL_USER: testuser
      MYSQL_PASSWORD: testpass
      MYSQL_ROOT_PASSWORD: testroot
    networks:
      - test-network
    healthcheck:
      test: ["CMD-SHELL", "mysql -u testuser -p testpass -e 'SELECT 1'"]
      interval: 10s
      timeout: 5s
      retries: 5

networks:
  test-network:
    driver: bridge
```

## 📊 Reports and Artifacts

The pipeline generates various reports:

### **Test Reports:**
- JUnit test results
- JaCoCo code coverage
- Integration test results

### **Security Reports:**
- OWASP Dependency Check
- Trivy vulnerability scans
- License compliance reports

### **Quality Reports:**
- SonarQube code quality metrics
- Performance test results

### **Build Artifacts:**
- JAR files
- Docker images
- Build metadata

## 🔧 Customization

### **Environment-Specific Deployments:**

Modify the deployment functions in the Jenkinsfile:

```groovy
def deployToDev(config) {
    // Add your dev deployment logic
    sshagent(['dev-server-ssh-key']) {
        sh """
            ssh user@${config.server} '
                cd /opt/library-app &&
                docker-compose pull &&
                docker-compose up -d
            '
        """
    }
}
```

### **Adding New Environments:**

1. Add new environment configuration in `getDeploymentConfig()`
2. Create corresponding credentials
3. Add deployment function
4. Update parameter choices

## 🚨 Troubleshooting

### **Common Issues:**

1. **Docker Permission Issues:**
   ```bash
   # Add Jenkins user to docker group
   sudo usermod -aG docker jenkins
   sudo systemctl restart jenkins
   ```

2. **Maven Memory Issues:**
   ```bash
   # Increase Maven memory in Jenkins
   MAVEN_OPTS="-Xmx2048m -XX:MaxPermSize=512m"
   ```

3. **SonarQube Connection Issues:**
   - Verify SonarQube server is accessible
   - Check token permissions
   - Ensure project exists in SonarQube

4. **Test Database Issues:**
   - Ensure MySQL container has sufficient resources
   - Check database initialization scripts
   - Verify test data setup

## 📈 Monitoring and Metrics

### **Pipeline Metrics:**
- Build success/failure rates
- Build duration trends
- Test coverage trends
- Security vulnerability trends

### **Application Metrics:**
- Health check status
- Performance benchmarks
- Deployment frequency
- Mean time to recovery (MTTR)

## 🔄 Maintenance

### **Regular Tasks:**
- Update security scanning tools
- Review and update dependencies
- Clean up old build artifacts
- Monitor resource usage
- Update credentials before expiration

This Jenkins pipeline provides enterprise-grade CI/CD automation with comprehensive testing, security scanning, and deployment capabilities for the Library of Alexandria project.