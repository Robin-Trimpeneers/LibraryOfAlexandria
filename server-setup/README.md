# Server Setup Guide for 192.168.129.139

This guide helps you prepare the target server (192.168.129.139) for deployment.

## 🖥️ Server Requirements

### **Operating System**: Ubuntu 20.04+ or similar Linux distribution
### **Resources**:
- **CPU**: 2+ cores
- **RAM**: 4GB+ (recommended 8GB)
- **Storage**: 20GB+ free space
- **Network**: Access to Docker Hub and GitHub

## 🛠️ Server Setup Steps

### 1. **Install Docker and Docker Compose**

```bash
# Update system
sudo apt update && sudo apt upgrade -y

# Install Docker
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh

# Add user to docker group
sudo usermod -aG docker $USER

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# Verify installation
docker --version
docker-compose --version
```

### 2. **Create Deployment User**

```bash
# Create deployment user (optional, can use existing user)
sudo useradd -m -s /bin/bash deploy
sudo usermod -aG docker deploy
sudo usermod -aG sudo deploy

# Set password
sudo passwd deploy
```

### 3. **Setup SSH Access**

#### **Option A: Password Authentication**
```bash
# Ensure SSH is installed and running
sudo apt install openssh-server -y
sudo systemctl enable ssh
sudo systemctl start ssh

# Configure SSH (edit /etc/ssh/sshd_config)
sudo sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
sudo systemctl restart ssh
```

#### **Option B: SSH Key Authentication (Recommended)**
```bash
# On Jenkins server, generate SSH key pair
ssh-keygen -t rsa -b 4096 -C "jenkins@your-domain"

# Copy public key to target server
ssh-copy-id username@192.168.129.139

# Or manually add to authorized_keys
cat ~/.ssh/id_rsa.pub | ssh username@192.168.129.139 "mkdir -p ~/.ssh && cat >> ~/.ssh/authorized_keys"
```

### 4. **Prepare Deployment Directories**

```bash
# Create application directories
sudo mkdir -p /opt/library-app
sudo mkdir -p /opt/library-app-dev
sudo mkdir -p /opt/library-app-staging

# Set ownership
sudo chown -R $USER:$USER /opt/library-app*

# Create log directories
mkdir -p /opt/library-app/logs
mkdir -p /opt/library-app-dev/logs
mkdir -p /opt/library-app-staging/logs
```

### 5. **Configure Firewall**

```bash
# Install UFW if not present
sudo apt install ufw -y

# Configure firewall rules
sudo ufw allow ssh
sudo ufw allow 8080/tcp    # Frontend
sudo ufw allow 5050/tcp    # Backend API
sudo ufw allow 8081/tcp    # PHPMyAdmin
sudo ufw allow 3306/tcp    # MySQL (if accessing externally)

# Enable firewall
sudo ufw --force enable
sudo ufw status
```

### 6. **Install Additional Tools**

```bash
# Install useful tools
sudo apt install -y curl wget git htop tree

# Install MySQL client (for database operations)
sudo apt install mysql-client -y
```

## 🔧 Jenkins Configuration

### **Required Jenkins Credentials**:

1. **deploy-user-credentials**
   ```
   Type: Username with password
   Username: deploy (or your chosen username)
   Password: [your-server-password]
   ```

2. **ssh-key-credentials** (if using SSH keys)
   ```
   Type: SSH Username with private key
   Username: deploy
   Private Key: [content of ~/.ssh/id_rsa]
   ```

### **Server Connection Test**:

```bash
# Test SSH connection from Jenkins server
ssh deploy@192.168.129.139 "echo 'Connection successful'"

# Test Docker access
ssh deploy@192.168.129.139 "docker --version"
```

## 🚀 Deployment Commands

### **Manual Deployment** (from local machine):

```bash
# Set environment variables
export ENVIRONMENT=dev
export DEPLOY_USER=deploy
export DOCKER_TAG=latest

# Run deployment script
chmod +x deploy.sh
./deploy.sh
```

### **Environment-Specific Deployments**:

```bash
# Development
ENVIRONMENT=dev ./deploy.sh

# Staging
ENVIRONMENT=staging ./deploy.sh

# Production (requires confirmation)
ENVIRONMENT=production ./deploy.sh
```

## 📊 Application URLs

After successful deployment:

- **Frontend**: http://192.168.129.139:8080
- **Backend API**: http://192.168.129.139:5050
- **PHPMyAdmin**: http://192.168.129.139:8081
- **Health Check**: http://192.168.129.139:5050/actuator/health

## 🔍 Monitoring and Logs

### **View Application Logs**:

```bash
# Navigate to deployment directory
cd /opt/library-app  # or /opt/library-app-dev for dev

# View all logs
docker-compose logs -f

# View specific service logs
docker-compose logs -f springboot-app
docker-compose logs -f mysql
docker-compose logs -f nginx
```

### **Check Service Status**:

```bash
# Check running containers
docker-compose ps

# Check system resources
htop

# Check disk usage
df -h
```

## 🚨 Troubleshooting

### **Common Issues**:

1. **Docker Permission Denied**:
   ```bash
   sudo usermod -aG docker $USER
   # Log out and log back in
   ```

2. **Port Already in Use**:
   ```bash
   # Check what's using the port
   sudo netstat -tulpn | grep :8080
   
   # Stop conflicting services
   sudo systemctl stop apache2  # if Apache is running
   ```

3. **Low Disk Space**:
   ```bash
   # Clean up Docker resources
   docker system prune -a
   
   # Remove old backups
   find /opt/library-app*/backups -name "*.tar.gz" -mtime +7 -delete
   ```

4. **Database Connection Issues**:
   ```bash
   # Check MySQL container
   docker-compose logs mysql
   
   # Reset MySQL data (CAUTION: This will delete all data)
   docker-compose down
   docker volume rm $(docker volume ls -q | grep mysql)
   docker-compose up -d
   ```

## 🔐 Security Recommendations

1. **Keep system updated**:
   ```bash
   sudo apt update && sudo apt upgrade -y
   ```

2. **Configure fail2ban** (SSH protection):
   ```bash
   sudo apt install fail2ban -y
   sudo systemctl enable fail2ban
   ```

3. **Regular backups**:
   ```bash
   # Create backup script
   cat > /home/deploy/backup.sh << 'EOF'
   #!/bin/bash
   cd /opt/library-app
   docker-compose exec -T mysql mysqldump -u root -p${MYSQL_ROOT_PASSWORD} librarydb > /backup/db_$(date +%Y%m%d).sql
   tar -czf /backup/app_$(date +%Y%m%d).tar.gz /opt/library-app
   # Keep only last 7 days
   find /backup -name "*.sql" -mtime +7 -delete
   find /backup -name "*.tar.gz" -mtime +7 -delete
   EOF
   
   chmod +x /home/deploy/backup.sh
   
   # Add to crontab for daily backups
   echo "0 2 * * * /home/deploy/backup.sh" | crontab -
   ```

4. **Monitor logs**:
   ```bash
   # Install log monitoring (optional)
   sudo apt install logwatch -y
   ```

## 📈 Performance Optimization

1. **Docker resource limits** (in docker-compose.yml):
   ```yaml
   services:
     springboot-app:
       deploy:
         resources:
           limits:
             memory: 1G
             cpus: '1.0'
   ```

2. **MySQL optimization**:
   ```yaml
   mysql:
     command: --innodb-buffer-pool-size=512M --max-connections=100
   ```

Your server at 192.168.129.139 is now ready for Library of Alexandria deployments! 🚀