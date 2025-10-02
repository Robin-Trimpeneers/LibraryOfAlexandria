#!/bin/bash

# Deployment script for Library of Alexandria to 192.168.129.139
# This script can be run directly on the target server or called by Jenkins

set -e

# Configuration
SERVER_IP="192.168.129.139"
APP_NAME="library-of-alexandria"
DEPLOY_USER="${DEPLOY_USER:-ubuntu}"
ENVIRONMENT="${ENVIRONMENT:-dev}"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging function
log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $1"
}

error() {
    echo -e "${RED}[ERROR]${NC} $1" >&2
}

success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

# Check if running on target server
check_environment() {
    local current_ip=$(hostname -I | awk '{print $1}')
    if [[ "$current_ip" == "$SERVER_IP" ]]; then
        log "Running directly on target server ($SERVER_IP)"
        LOCAL_DEPLOYMENT=true
    else
        log "Running remote deployment to $SERVER_IP"
        LOCAL_DEPLOYMENT=false
    fi
}

# Setup deployment directories
setup_directories() {
    local base_path="/opt/library-app"
    
    case $ENVIRONMENT in
        "dev")
            DEPLOY_PATH="${base_path}-dev"
            COMPOSE_FILE="docker-compose.dev.yml"
            ;;
        "staging")
            DEPLOY_PATH="${base_path}-staging"
            COMPOSE_FILE="docker-compose.yml"
            ;;
        "production")
            DEPLOY_PATH="${base_path}"
            COMPOSE_FILE="docker-compose.yml"
            ;;
        *)
            error "Unknown environment: $ENVIRONMENT"
            exit 1
            ;;
    esac
    
    log "Setting up deployment directory: $DEPLOY_PATH"
    
    if [[ "$LOCAL_DEPLOYMENT" == "true" ]]; then
        sudo mkdir -p $DEPLOY_PATH
        sudo mkdir -p $DEPLOY_PATH/backups
        sudo mkdir -p $DEPLOY_PATH/logs
        sudo chown -R $USER:$USER $DEPLOY_PATH
    else
        ssh -o StrictHostKeyChecking=no $DEPLOY_USER@$SERVER_IP "
            sudo mkdir -p $DEPLOY_PATH
            sudo mkdir -p $DEPLOY_PATH/backups
            sudo mkdir -p $DEPLOY_PATH/logs
            sudo chown -R $DEPLOY_USER:$DEPLOY_USER $DEPLOY_PATH
        "
    fi
}

# Backup existing deployment
backup_current_deployment() {
    log "Creating backup of current deployment..."
    
    local backup_name="backup_$(date +%Y%m%d_%H%M%S)"
    
    if [[ "$LOCAL_DEPLOYMENT" == "true" ]]; then
        if [[ -f "$DEPLOY_PATH/docker-compose.yml" ]] || [[ -f "$DEPLOY_PATH/docker-compose.dev.yml" ]]; then
            cd $DEPLOY_PATH
            
            # Database backup
            if docker-compose ps | grep -q mysql; then
                log "Creating database backup..."
                docker-compose exec -T mysql mysqldump -u root -p${MYSQL_ROOT_PASSWORD} librarydb > backups/db_${backup_name}.sql 2>/dev/null || warning "Database backup failed"
            fi
            
            # Application files backup
            tar -czf backups/app_${backup_name}.tar.gz . --exclude=backups --exclude=logs 2>/dev/null || warning "Application backup failed"
            
            success "Backup created: $backup_name"
        else
            warning "No existing deployment found to backup"
        fi
    else
        ssh -o StrictHostKeyChecking=no $DEPLOY_USER@$SERVER_IP "
            if [[ -f '$DEPLOY_PATH/docker-compose.yml' ]] || [[ -f '$DEPLOY_PATH/docker-compose.dev.yml' ]]; then
                cd $DEPLOY_PATH
                
                # Database backup
                if docker-compose ps | grep -q mysql; then
                    echo 'Creating database backup...'
                    docker-compose exec -T mysql mysqldump -u root -p\${MYSQL_ROOT_PASSWORD} librarydb > backups/db_${backup_name}.sql 2>/dev/null || echo 'Database backup failed'
                fi
                
                # Application files backup
                tar -czf backups/app_${backup_name}.tar.gz . --exclude=backups --exclude=logs 2>/dev/null || echo 'Application backup failed'
                
                echo 'Backup created: ${backup_name}'
            else
                echo 'No existing deployment found to backup'
            fi
        "
    fi
}

# Copy application files
copy_files() {
    log "Copying application files..."
    
    # Create .env file if it doesn't exist
    if [[ ! -f ".env" ]]; then
        warning ".env file not found, creating from template..."
        if [[ -f ".env.template" ]]; then
            cp .env.template .env
            warning "Please edit .env file with your actual values before deployment"
        else
            # Create basic .env file
            cat > .env << 'EOF'
# Database Configuration
SPRING_DATASOURCE_USERNAME=appuser
SPRING_DATASOURCE_PASSWORD=change-this-password
MYSQL_USER=appuser
MYSQL_PASSWORD=change-this-password
MYSQL_ROOT_PASSWORD=change-this-root-password

# JWT Configuration
JWT_SECRET=change-this-jwt-secret-must-be-64-characters-minimum

# Google Books API
GOOGLE_API_KEY=your-google-books-api-key-here

# Application Profile
SPRING_PROFILES_ACTIVE=prod
EOF
            error "Created basic .env file. EDIT IT WITH YOUR VALUES before continuing!"
            exit 1
        fi
    fi
    
    if [[ "$LOCAL_DEPLOYMENT" == "true" ]]; then
        cp $COMPOSE_FILE $DEPLOY_PATH/
        cp .env $DEPLOY_PATH/
        cp nginx.conf $DEPLOY_PATH/
        cp init.sql $DEPLOY_PATH/
        cp -r Frontend $DEPLOY_PATH/
        
        # Update docker-compose.yml to use the correct image tag
        if [[ -n "$DOCKER_TAG" ]]; then
            sed -i "s|image: robintrimpeneerspxl/librarydb.*|image: robintrimpeneerspxl/librarydb:$DOCKER_TAG|g" $DEPLOY_PATH/$COMPOSE_FILE
        fi
    else
        scp -o StrictHostKeyChecking=no $COMPOSE_FILE $DEPLOY_USER@$SERVER_IP:$DEPLOY_PATH/
        scp -o StrictHostKeyChecking=no .env $DEPLOY_USER@$SERVER_IP:$DEPLOY_PATH/
        scp -o StrictHostKeyChecking=no nginx.conf $DEPLOY_USER@$SERVER_IP:$DEPLOY_PATH/
        scp -o StrictHostKeyChecking=no init.sql $DEPLOY_USER@$SERVER_IP:$DEPLOY_PATH/
        scp -r -o StrictHostKeyChecking=no Frontend $DEPLOY_USER@$SERVER_IP:$DEPLOY_PATH/
        
        # Update docker-compose.yml to use the correct image tag
        if [[ -n "$DOCKER_TAG" ]]; then
            ssh -o StrictHostKeyChecking=no $DEPLOY_USER@$SERVER_IP "
                sed -i 's|image: robintrimpeneerspxl/librarydb.*|image: robintrimpeneerspxl/librarydb:$DOCKER_TAG|g' $DEPLOY_PATH/$COMPOSE_FILE
            "
        fi
    fi
    
    success "Files copied successfully"
}

# Deploy application
deploy_application() {
    log "Deploying application on $SERVER_IP..."
    
    if [[ "$LOCAL_DEPLOYMENT" == "true" ]]; then
        cd $DEPLOY_PATH
        
        # Pull latest image
        if [[ -n "$DOCKER_TAG" ]]; then
            docker pull robintrimpeneerspxl/librarydb:$DOCKER_TAG
        fi
        
        # Stop existing containers
        docker-compose -f $COMPOSE_FILE down || warning "No existing containers to stop"
        
        # Start new deployment
        docker-compose -f $COMPOSE_FILE up -d
        
        success "Application deployed locally"
    else
        ssh -o StrictHostKeyChecking=no $DEPLOY_USER@$SERVER_IP "
            cd $DEPLOY_PATH
            
            # Pull latest image
            if [[ -n '$DOCKER_TAG' ]]; then
                docker pull robintrimpeneerspxl/librarydb:$DOCKER_TAG
            fi
            
            # Stop existing containers
            docker-compose -f $COMPOSE_FILE down || echo 'No existing containers to stop'
            
            # Start new deployment
            docker-compose -f $COMPOSE_FILE up -d
        "
        
        success "Application deployed remotely to $SERVER_IP"
    fi
}

# Health check
health_check() {
    log "Performing health check..."
    
    local health_url="http://$SERVER_IP:8080"
    local api_health_url="http://$SERVER_IP:5050/actuator/health"
    
    # Wait for services to start
    sleep 30
    
    # Check API health
    for i in {1..10}; do
        if curl -f -s $api_health_url > /dev/null 2>&1; then
            success "API health check passed"
            break
        else
            warning "API health check failed, attempt $i/10"
            if [[ $i -eq 10 ]]; then
                error "API health check failed after 10 attempts"
                return 1
            fi
            sleep 10
        fi
    done
    
    # Check frontend
    if curl -f -s $health_url > /dev/null 2>&1; then
        success "Frontend health check passed"
        success "🚀 Application is healthy and running at: $health_url"
    else
        error "Frontend health check failed"
        return 1
    fi
}

# Cleanup old Docker resources
cleanup() {
    log "Cleaning up old Docker resources..."
    
    if [[ "$LOCAL_DEPLOYMENT" == "true" ]]; then
        docker image prune -f
        docker container prune -f
        docker volume prune -f
    else
        ssh -o StrictHostKeyChecking=no $DEPLOY_USER@$SERVER_IP "
            docker image prune -f
            docker container prune -f
            docker volume prune -f
        "
    fi
    
    success "Cleanup completed"
}

# Rollback function
rollback() {
    warning "Rolling back deployment..."
    
    local latest_backup
    if [[ "$LOCAL_DEPLOYMENT" == "true" ]]; then
        latest_backup=$(ls -t $DEPLOY_PATH/backups/app_*.tar.gz 2>/dev/null | head -1)
    else
        latest_backup=$(ssh -o StrictHostKeyChecking=no $DEPLOY_USER@$SERVER_IP "ls -t $DEPLOY_PATH/backups/app_*.tar.gz 2>/dev/null | head -1")
    fi
    
    if [[ -n "$latest_backup" ]]; then
        log "Rolling back to: $(basename $latest_backup)"
        
        if [[ "$LOCAL_DEPLOYMENT" == "true" ]]; then
            cd $DEPLOY_PATH
            docker-compose down
            tar -xzf $latest_backup
            docker-compose up -d
        else
            ssh -o StrictHostKeyChecking=no $DEPLOY_USER@$SERVER_IP "
                cd $DEPLOY_PATH
                docker-compose down
                tar -xzf $latest_backup
                docker-compose up -d
            "
        fi
        
        success "Rollback completed"
    else
        error "No backup found for rollback"
        return 1
    fi
}

# Main deployment function
main() {
    log "🚀 Starting deployment of Library of Alexandria"
    log "Target: $SERVER_IP"
    log "Environment: $ENVIRONMENT"
    log "User: $DEPLOY_USER"
    
    check_environment
    setup_directories
    
    # Production requires explicit confirmation
    if [[ "$ENVIRONMENT" == "production" ]]; then
        echo -n "⚠️  Are you sure you want to deploy to PRODUCTION? (yes/no): "
        read -r confirmation
        if [[ "$confirmation" != "yes" ]]; then
            warning "Production deployment cancelled"
            exit 0
        fi
    fi
    
    backup_current_deployment
    copy_files
    deploy_application
    
    if health_check; then
        success "🎉 Deployment completed successfully!"
        success "📱 Frontend: http://$SERVER_IP:8080"
        success "🔧 API: http://$SERVER_IP:5050"
        success "📊 PHPMyAdmin: http://$SERVER_IP:8081"
        cleanup
    else
        error "❌ Deployment failed health check"
        echo -n "Would you like to rollback? (yes/no): "
        read -r rollback_choice
        if [[ "$rollback_choice" == "yes" ]]; then
            rollback
        fi
        exit 1
    fi
}

# Handle script arguments
case "${1:-deploy}" in
    "deploy")
        main
        ;;
    "rollback")
        rollback
        ;;
    "health-check")
        health_check
        ;;
    "cleanup")
        cleanup
        ;;
    *)
        echo "Usage: $0 {deploy|rollback|health-check|cleanup}"
        echo ""
        echo "Commands:"
        echo "  deploy      - Deploy application (default)"
        echo "  rollback    - Rollback to previous version"
        echo "  health-check - Check application health"
        echo "  cleanup     - Clean up Docker resources"
        echo ""
        echo "Environment variables:"
        echo "  ENVIRONMENT - dev|staging|production (default: dev)"
        echo "  DEPLOY_USER - SSH user (default: ubuntu)"
        echo "  DOCKER_TAG  - Docker image tag to deploy"
        exit 1
        ;;
esac