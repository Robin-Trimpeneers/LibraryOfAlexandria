# Dependencies and Setup Guide

## 🔐 Environment Variables & Security

### **Why .env files aren't in Git:**
- `.env` files contain sensitive information (API keys, passwords, secrets)
- They're in `.gitignore` to prevent accidental commits
- Each environment (dev/staging/production) needs its own configuration

### **How Jenkins Handles Environment Variables:**

Jenkins uses **Credentials** instead of `.env` files for security:

## 🔑 Required Jenkins Credentials

Configure these in Jenkins: **Manage Jenkins → Credentials → Global → Add Credentials**

### 1. **Database Credentials**
```
ID: mysql-credentials
Type: Username with password
Username: appuser
Password: q[M}V+_QdOJ3Ljp,1cwZhz|r
Description: MySQL database credentials
```

### 2. **JWT Secret**
```
ID: jwt-secret
Type: Secret text
Secret: mySecretKey123456789012345678901234567890123456789012345678901234567890
Description: JWT signing secret (must be 64+ characters)
```

### 3. **Google Books API Key**
```
ID: google-api-key
Type: Secret text
Secret: AIzaSyDiQaqRs5l8AOmH1MHkLLL7FYF7OOWaV3o
Description: Google Books API key
```

### 4. **Deployment User**
```
ID: deploy-user-credentials
Type: Username with password
Username: [your-ssh-username-for-192.168.129.139]
Password: [your-ssh-password]
Description: SSH credentials for deployment server
```

### 5. **SSH Key (Recommended)**
```
ID: ssh-key-credentials
Type: SSH Username with private key
Username: [your-ssh-username]
Private Key: [paste your private key content]
Description: SSH key for secure deployment
```

## 🛠️ Jenkins Dependencies

### **Required Jenkins Plugins:**

Install these via **Manage Jenkins → Manage Plugins → Available**:

```bash
# Core CI/CD plugins
Pipeline                    # Pipeline support
Pipeline: Stage View        # Visual pipeline view
Docker Pipeline             # Docker integration
Maven Integration           # Maven support
Git                        # Git SCM support
SSH Agent                  # SSH key management

# Testing & Reports
JUnit                      # Test result publishing
Workspace Cleanup          # Clean workspace after builds

# Optional but recommended
Blue Ocean                 # Modern UI
Timestamper               # Add timestamps to logs
Build Timeout             # Prevent hanging builds
```

### **Global Tool Configuration:**

Go to **Manage Jenkins → Global Tool Configuration**:

#### **Maven:**
```
Name: Maven-3.9.4
Install automatically: ✅
Version: 3.9.4
```

#### **JDK:**
```
Name: JDK-21
Install automatically: ✅
Installer: Install from adoptium.net
Version: jdk-21+35
```

#### **Git:**
```
Name: Default
Path to Git executable: git
```

## 🖥️ Server Dependencies (192.168.129.139)

### **Required Software on Target Server:**

```bash
# 1. Docker & Docker Compose
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh get-docker.sh
sudo usermod -aG docker $USER

# Install Docker Compose
sudo curl -L "https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m)" -o /usr/local/bin/docker-compose
sudo chmod +x /usr/local/bin/docker-compose

# 2. SSH Server
sudo apt update
sudo apt install openssh-server -y
sudo systemctl enable ssh
sudo systemctl start ssh

# 3. Basic utilities
sudo apt install curl wget git -y

# 4. MySQL client (for database operations)
sudo apt install mysql-client -y
```

### **Server Setup Checklist:**

```bash
# 1. Create deployment directories
sudo mkdir -p /opt/library-app
sudo mkdir -p /opt/library-app-dev
sudo mkdir -p /opt/library-app-staging
sudo chown $USER:$USER /opt/library-app*

# 2. Configure firewall
sudo ufw allow ssh
sudo ufw allow 8080/tcp    # Frontend
sudo ufw allow 5050/tcp    # Backend API
sudo ufw allow 8081/tcp    # PHPMyAdmin
sudo ufw --force enable

# 3. Test Docker
docker --version
docker-compose --version
docker run hello-world

# 4. Verify SSH access from Jenkins
# From Jenkins server: ssh username@192.168.129.139
```

## 🔧 Local Development Dependencies

### **For Local Development:**

```bash
# 1. Java 21
# Download from: https://adoptium.net/

# 2. Maven 3.9+
# Download from: https://maven.apache.org/download.cgi

# 3. Docker Desktop
# Download from: https://www.docker.com/products/docker-desktop

# 4. Git
# Download from: https://git-scm.com/

# 5. IDE (Optional)
# IntelliJ IDEA, VS Code, or Eclipse
```

### **Verify Local Setup:**
```bash
java -version    # Should show Java 21
mvn -version     # Should show Maven 3.9+
docker --version
git --version
```

## 🚀 Getting Your API Keys

### **Google Books API Key:**

1. **Go to Google Cloud Console**: https://console.cloud.google.com/
2. **Create a new project** or select existing one
3. **Enable the Books API**:
   - Go to "APIs & Services" → "Library"
   - Search for "Books API"
   - Click "Enable"
4. **Create credentials**:
   - Go to "APIs & Services" → "Credentials"
   - Click "Create Credentials" → "API Key"
   - Copy the generated key
5. **Restrict the key** (recommended):
   - Click on the key to edit
   - Under "API restrictions" → Select "Restrict key"
   - Choose "Books API"

### **JWT Secret Generation:**

```bash
# Generate a secure JWT secret (64+ characters)
openssl rand -base64 64

# Or use online generator: https://jwtsecret.com/generate
```

## 📋 Environment-Specific Configuration

### **Development (.env.dev):**
```properties
SPRING_DATASOURCE_USERNAME=appuser
SPRING_DATASOURCE_PASSWORD=devpass123
MYSQL_USER=appuser
MYSQL_PASSWORD=devpass123
MYSQL_ROOT_PASSWORD=rootdev123
JWT_SECRET=dev-jwt-secret-key
GOOGLE_API_KEY=your-google-api-key
SPRING_PROFILES_ACTIVE=dev
```

### **Production (.env.prod):**
```properties
SPRING_DATASOURCE_USERNAME=appuser
SPRING_DATASOURCE_PASSWORD=super-secure-prod-password
MYSQL_USER=appuser
MYSQL_PASSWORD=super-secure-prod-password
MYSQL_ROOT_PASSWORD=super-secure-root-password
JWT_SECRET=super-secure-jwt-secret-64-characters-minimum
GOOGLE_API_KEY=your-google-api-key
SPRING_PROFILES_ACTIVE=prod
```

## 🧪 Testing the Setup

### **1. Test Jenkins Connection:**
```bash
# In Jenkins, create a simple test job:
pipeline {
    agent any
    stages {
        stage('Test') {
            steps {
                echo "Testing credentials..."
                echo "DB User: ${env.DB_CREDENTIALS_USR}"
                echo "API Key exists: ${env.GOOGLE_API_KEY ? 'Yes' : 'No'}"
            }
        }
    }
}
```

### **2. Test Server Connection:**
```bash
# From Jenkins server or your machine:
ssh username@192.168.129.139 "echo 'Connection successful'"
ssh username@192.168.129.139 "docker --version"
```

### **3. Test Local Development:**
```bash
# Clone repo and test locally
git clone https://github.com/Robin-Trimpeneers/LibraryOfAlexandria.git
cd LibraryOfAlexandria

# Create local .env file
cp .env.template .env
# Edit .env with your values

# Test with Docker Compose
docker-compose up -d
curl http://localhost:8080
```

## 🚨 Security Best Practices

1. **Never commit sensitive data**:
   - Always use `.gitignore` for `.env` files
   - Use Jenkins credentials for CI/CD
   - Rotate secrets regularly

2. **Use different credentials per environment**:
   - Dev, staging, and production should have separate secrets
   - Use strong passwords (20+ characters)

3. **Limit API key permissions**:
   - Restrict Google API key to specific APIs
   - Use IP restrictions when possible

4. **Secure server access**:
   - Use SSH keys instead of passwords
   - Configure firewall properly
   - Keep server updated

## 📞 Troubleshooting

### **Common Issues:**

1. **"Credential not found" in Jenkins**:
   - Verify credential ID matches exactly
   - Check credential scope (Global vs Project)

2. **SSH connection fails**:
   - Verify SSH service is running on server
   - Check firewall settings
   - Test SSH manually first

3. **Docker permission denied**:
   - Add user to docker group: `sudo usermod -aG docker $USER`
   - Log out and back in

4. **API key invalid**:
   - Verify Google Books API is enabled
   - Check API key restrictions
   - Test API key manually: `curl "https://www.googleapis.com/books/v1/volumes?q=isbn:9780140449136&key=YOUR_API_KEY"`

This setup ensures your sensitive data stays secure while enabling automated CI/CD! 🔐