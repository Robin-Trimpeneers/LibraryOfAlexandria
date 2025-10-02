# Quick Jenkins Setup Guide

## 🚀 Option 1: Docker-based Jenkins (Recommended)

### Start Jenkins with Docker Compose:

```powershell
# Navigate to Jenkins directory
cd jenkins

# Start Jenkins and SonarQube
docker-compose -f docker-compose.jenkins.yml up -d

# Check status
docker-compose -f docker-compose.jenkins.yml ps
```

### Access Services:
- **Jenkins**: http://localhost:8080
- **SonarQube**: http://localhost:9000 (admin/admin)

### Initial Setup:

1. **Get Jenkins Initial Password:**
   ```powershell
   docker exec library-jenkins cat /var/jenkins_home/secrets/initialAdminPassword
   ```

2. **Complete Jenkins Setup Wizard:**
   - Install suggested plugins
   - Create admin user
   - Configure Jenkins URL: http://localhost:8080

3. **Run Setup Script:**
   ```powershell
   # In WSL or Git Bash
   cd jenkins
   chmod +x setup.sh
   ./setup.sh
   ```

## 🛠️ Option 2: Existing Jenkins Installation

If you have Jenkins already running:

1. **Install Required Plugins** (see jenkins/README.md for full list)
2. **Configure Global Tools:**
   - Maven 3.9.4
   - JDK 21
   - Docker

3. **Add Credentials:**
   - MySQL credentials
   - Docker Hub credentials
   - API keys (JWT, Google Books)
   - Server configurations

4. **Create Pipeline Job:**
   - New Item → Pipeline
   - Name: "Library-of-Alexandria"
   - Pipeline script from SCM
   - Repository: https://github.com/Robin-Trimpeneers/LibraryOfAlexandria.git
   - Script Path: Jenkinsfile

## 🔧 Quick Configuration

### Minimum Required Credentials:

```bash
# In Jenkins → Manage Credentials → Global
mysql-credentials: appuser / [password-from-.env]
jwt-secret: [your-jwt-secret-key]
google-api-key: [your-google-books-api-key]
docker-hub-credentials: [dockerhub-username] / [dockerhub-password]
```

### Test Pipeline:

1. **Trigger Build:**
   - Go to Jenkins dashboard
   - Click "Library-of-Alexandria" job
   - Click "Build with Parameters"
   - Select Environment: `dev`
   - Click "Build"

2. **Monitor Build:**
   - View console output
   - Check stage progress
   - Review test reports

## 📊 Pipeline Features

✅ **Automated Testing**: Unit, integration, and security tests  
✅ **Code Quality**: SonarQube analysis with quality gates  
✅ **Security Scanning**: OWASP dependency check, Trivy container scanning  
✅ **Multi-Environment**: Deploy to dev, staging, or production  
✅ **Docker Integration**: Build and push container images  
✅ **Notifications**: Slack and email alerts  
✅ **Approval Gates**: Manual approval for production deployments  
✅ **Rollback Support**: Easy rollback capabilities  

## 🚨 Troubleshooting

### Docker Permission Issues:
```bash
# Add jenkins user to docker group
sudo usermod -aG jenkins docker
sudo systemctl restart jenkins
```

### Memory Issues:
```bash
# Increase Jenkins memory
JAVA_OPTS="-Xmx2048m -XX:MaxPermSize=512m"
```

### Plugin Installation Issues:
- Use Jenkins Plugin Manager
- Restart Jenkins after plugin installation
- Check Jenkins logs for errors

## 📚 Next Steps

1. **Configure Environments**: Set up dev/staging/production servers
2. **Add Monitoring**: Integrate with monitoring tools
3. **Security Hardening**: Configure security settings
4. **Backup Strategy**: Set up Jenkins backup procedures

For detailed configuration, see [`jenkins/README.md`](README.md)