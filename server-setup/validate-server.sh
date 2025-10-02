#!/bin/bash

# Server Validation Script for 192.168.129.139
# Run this script on the target server to verify deployment readiness

set -e

SERVER_IP="192.168.129.139"
REQUIRED_PORTS=(22 8080 5050 8081 3306)
REQUIRED_PACKAGES=(docker docker-compose curl wget git)

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() { echo -e "${BLUE}[INFO]${NC} $1"; }
success() { echo -e "${GREEN}[✓]${NC} $1"; }
warning() { echo -e "${YELLOW}[!]${NC} $1"; }
error() { echo -e "${RED}[✗]${NC} $1"; }

echo "🏛️ Library of Alexandria - Server Validation"
echo "=============================================="
echo "Validating server: $SERVER_IP"
echo ""

# Check if running on correct server
log "Checking server IP..."
CURRENT_IP=$(hostname -I | awk '{print $1}')
if [[ "$CURRENT_IP" == "$SERVER_IP" ]]; then
    success "Running on correct server: $SERVER_IP"
else
    warning "Running on $CURRENT_IP, expected $SERVER_IP"
fi

# Check OS
log "Checking operating system..."
if [[ -f /etc/os-release ]]; then
    . /etc/os-release
    success "OS: $PRETTY_NAME"
else
    warning "Cannot determine OS version"
fi

# Check system resources
log "Checking system resources..."
TOTAL_RAM=$(free -h | awk '/^Mem:/ {print $2}')
AVAILABLE_DISK=$(df -h / | awk 'NR==2 {print $4}')
CPU_CORES=$(nproc)

echo "  RAM: $TOTAL_RAM"
echo "  CPU Cores: $CPU_CORES"
echo "  Available Disk: $AVAILABLE_DISK"

if [[ $(free -m | awk '/^Mem:/ {print $2}') -lt 3000 ]]; then
    warning "Less than 4GB RAM available. Recommended: 4GB+"
else
    success "Sufficient RAM available"
fi

# Check required packages
log "Checking required packages..."
for package in "${REQUIRED_PACKAGES[@]}"; do
    if command -v $package &> /dev/null; then
        case $package in
            "docker")
                DOCKER_VERSION=$(docker --version 2>/dev/null | cut -d' ' -f3 | cut -d',' -f1)
                success "Docker installed: $DOCKER_VERSION"
                ;;
            "docker-compose")
                COMPOSE_VERSION=$(docker-compose --version 2>/dev/null | cut -d' ' -f3 | cut -d',' -f1)
                success "Docker Compose installed: $COMPOSE_VERSION"
                ;;
            *)
                success "$package installed"
                ;;
        esac
    else
        error "$package not found"
    fi
done

# Check Docker service
log "Checking Docker service..."
if systemctl is-active --quiet docker; then
    success "Docker service is running"
else
    error "Docker service is not running"
fi

# Check Docker permissions
log "Checking Docker permissions..."
if docker ps &> /dev/null; then
    success "Docker accessible without sudo"
else
    warning "Docker requires sudo (user not in docker group)"
fi

# Check ports
log "Checking required ports..."
for port in "${REQUIRED_PORTS[@]}"; do
    if ss -tulpn | grep -q ":$port "; then
        warning "Port $port is already in use"
    else
        success "Port $port is available"
    fi
done

# Check firewall
log "Checking firewall configuration..."
if command -v ufw &> /dev/null; then
    if ufw status | grep -q "Status: active"; then
        success "UFW firewall is active"
        
        # Check if required ports are allowed
        for port in 22 8080 5050 8081; do
            if ufw status | grep -q "$port"; then
                success "Port $port is allowed in firewall"
            else
                warning "Port $port is not allowed in firewall"
            fi
        done
    else
        warning "UFW firewall is not active"
    fi
else
    warning "UFW not installed"
fi

# Check deployment directories
log "Checking deployment directories..."
DEPLOY_DIRS=("/opt/library-app" "/opt/library-app-dev" "/opt/library-app-staging")
for dir in "${DEPLOY_DIRS[@]}"; do
    if [[ -d "$dir" ]]; then
        if [[ -w "$dir" ]]; then
            success "Directory $dir exists and is writable"
        else
            warning "Directory $dir exists but is not writable"
        fi
    else
        warning "Directory $dir does not exist"
    fi
done

# Check SSH configuration
log "Checking SSH configuration..."
if systemctl is-active --quiet ssh; then
    success "SSH service is running"
    
    SSH_PORT=$(grep -E "^Port" /etc/ssh/sshd_config | awk '{print $2}' || echo "22")
    success "SSH running on port: $SSH_PORT"
    
    if grep -q "PasswordAuthentication yes" /etc/ssh/sshd_config; then
        success "Password authentication enabled"
    else
        warning "Password authentication may be disabled"
    fi
else
    error "SSH service is not running"
fi

# Test internet connectivity
log "Testing internet connectivity..."
if curl -s --connect-timeout 5 https://google.com > /dev/null; then
    success "Internet connectivity working"
else
    error "No internet connectivity"
fi

# Test Docker Hub connectivity
log "Testing Docker Hub connectivity..."
if curl -s --connect-timeout 5 https://hub.docker.com > /dev/null; then
    success "Docker Hub accessible"
else
    error "Cannot reach Docker Hub"
fi

# Test MySQL client
log "Testing MySQL client..."
if command -v mysql &> /dev/null; then
    success "MySQL client installed"
else
    warning "MySQL client not installed (recommended for database operations)"
fi

# Performance test
log "Running basic performance test..."
echo "  Testing disk I/O..."
DISK_SPEED=$(dd if=/dev/zero of=/tmp/test_file bs=1M count=100 2>&1 | grep -o '[0-9.]* MB/s' | tail -1)
rm -f /tmp/test_file
echo "  Disk write speed: $DISK_SPEED"

echo ""
echo "🔍 Validation Summary"
echo "===================="

# Generate recommendations
echo ""
echo "📋 Recommendations:"

if ! command -v docker &> /dev/null; then
    echo "❌ Install Docker: curl -fsSL https://get.docker.com -o get-docker.sh && sudo sh get-docker.sh"
fi

if ! command -v docker-compose &> /dev/null; then
    echo "❌ Install Docker Compose: sudo curl -L \"https://github.com/docker/compose/releases/latest/download/docker-compose-\$(uname -s)-\$(uname -m)\" -o /usr/local/bin/docker-compose && sudo chmod +x /usr/local/bin/docker-compose"
fi

if ! docker ps &> /dev/null 2>&1; then
    echo "❌ Add user to docker group: sudo usermod -aG docker \$USER && newgrp docker"
fi

if ! systemctl is-active --quiet docker; then
    echo "❌ Start Docker service: sudo systemctl start docker && sudo systemctl enable docker"
fi

for dir in "${DEPLOY_DIRS[@]}"; do
    if [[ ! -d "$dir" ]]; then
        echo "❌ Create deployment directory: sudo mkdir -p $dir && sudo chown \$USER:\$USER $dir"
    fi
done

if ! command -v ufw &> /dev/null || ! ufw status | grep -q "Status: active"; then
    echo "❌ Configure firewall: sudo apt install ufw && sudo ufw allow ssh && sudo ufw allow 8080 && sudo ufw allow 5050 && sudo ufw allow 8081 && sudo ufw enable"
fi

echo ""
echo "✅ Server validation completed!"
echo "🚀 If all recommendations are addressed, the server is ready for deployment."