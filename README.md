# Library of Alexandria 📚

A full-stack book library management application with Spring Boot backend and vanilla JavaScript frontend.

## 🏗️ Architecture

- **Backend**: Spring Boot 3.4.2 with Java 21, MySQL, JWT Authentication
- **Frontend**: Vanilla HTML/CSS/JavaScript with Bootstrap
- **Database**: MySQL 8.0
- **Proxy**: Nginx for serving frontend and API routing
- **Containerization**: Docker & Docker Compose

## 🚀 Quick Start

### Prerequisites

- Docker and Docker Compose installed
- Git
- (Optional) Java 21 and Maven for local development
- (Optional) Jenkins for CI/CD pipeline

### 1. Clone the Repository

```bash
git clone https://github.com/Robin-Trimpeneers/LibraryOfAlexandria.git
cd LibraryOfAlexandria
```

### 2. Set Up Environment Variables

The `.env` file is already configured with default values. **Important**: 

- **Google Books API**: Get your API key from [Google Cloud Console](https://console.cloud.google.com/) and replace `your_google_books_api_key_here` in `.env`
- For production, change the default passwords in `.env`

### 3. Run with Docker Compose

```bash
# Start all services
docker-compose up -d

# View logs
docker-compose logs -f

# Stop services
docker-compose down
```

### 4. Access the Application

- **Frontend**: http://localhost:8080
- **Backend API**: http://localhost:5050
- **PHPMyAdmin**: http://localhost:8081 (user: appuser, password: from .env)

## 🔄 CI/CD Pipeline Options

### GitHub Actions (Included)
Automated CI/CD with GitHub Actions for testing, security scanning, building, and deployment.

### Jenkins Pipeline (Available)
Comprehensive Jenkins pipeline with advanced features:

```bash
# Quick Jenkins setup with Docker
cd jenkins
docker-compose -f docker-compose.jenkins.yml up -d

# Access Jenkins at http://localhost:8080
# Follow setup instructions in jenkins/README.md
```

**Jenkins Features:**
- ✅ Multi-environment deployments (dev/staging/production)
- ✅ Deployment to 192.168.129.139 server
- ✅ Comprehensive security scanning (OWASP, Trivy)
- ✅ Code quality analysis (SonarQube integration)
- ✅ Performance testing
- ✅ Slack/Email notifications
- ✅ Blue-green deployments
- ✅ Rollback capabilities
- ✅ Automated backup procedures

**Quick Deployment to Server:**
```bash
# Manual deployment to 192.168.129.139
export ENVIRONMENT=dev
export DEPLOY_USER=your-username
./deploy.sh

# Or use Jenkins pipeline for automated deployment
```

See [`jenkins/README.md`](jenkins/README.md) for detailed Jenkins setup instructions.
See [`server-setup/README.md`](server-setup/README.md) for server preparation guide.

## 🛠️ Development Setup

### Local Backend Development

```bash
cd Backend

# Run with Maven (requires Java 21)
./mvnw spring-boot:run

# Or run tests
./mvnw test
```

### Local Frontend Development

Simply serve the Frontend directory with any web server or open `index.html` in a browser.

## 📊 Database Schema

The application uses MySQL with JPA/Hibernate. Database schema is automatically managed by Hibernate DDL.

## 🔧 Configuration

### Environment Variables

| Variable | Description | Required |
|----------|-------------|----------|
| `SPRING_DATASOURCE_USERNAME` | Database username | Yes |
| `SPRING_DATASOURCE_PASSWORD` | Database password | Yes |
| `JWT_SECRET` | JWT signing secret | Yes |
| `GOOGLE_API_KEY` | Google Books API key | Yes |
| `MYSQL_ROOT_PASSWORD` | MySQL root password | Yes |

### Application Properties

Key configurations in `Backend/src/main/resources/application.properties`:

- Server runs on port 5050
- Database connection via environment variables
- JWT expiration: 24 hours
- Hibernate DDL: validate mode (production)

## 🐳 Docker Services

- **springboot-app**: Java application (port 5050)
- **mysql**: Database server (port 3306)
- **nginx**: Web server/proxy (port 8080)
- **phpmyadmin**: Database admin (port 8081)

## 🧪 Testing

```bash
# Backend tests
cd Backend
./mvnw test

# Integration tests with Docker
docker-compose -f docker-compose.test.yml up --abort-on-container-exit

# Jenkins pipeline testing
# See jenkins/README.md for comprehensive CI/CD setup
```

## 🚢 Deployment

### Production Considerations

1. **Security**: Change all default passwords and secrets
2. **SSL**: Configure HTTPS in nginx
3. **Environment**: Set `SPRING_PROFILES_ACTIVE=prod`
4. **Monitoring**: Use application health endpoints
5. **Backup**: Regular MySQL backups

### Health Checks

- **Application**: http://localhost:5050/actuator/health
- **Database**: Built-in MySQL health check

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## 📝 API Documentation

The backend provides RESTful APIs for:

- **Authentication**: `/api/auth/login`, `/api/auth/register`
- **Books**: `/api/books` (CRUD operations)
- **Users**: `/api/users` (user management)
- **Health**: `/actuator/health`

## 🐛 Troubleshooting

### Common Issues

1. **Port conflicts**: Ensure ports 3306, 5050, 8080, 8081 are available
2. **Google API**: Verify your API key is valid and has Books API enabled
3. **Database**: Check if MySQL container is healthy: `docker-compose ps`
4. **CORS issues**: Frontend must access backend through nginx proxy (port 8080)

### Logs

```bash
# View all logs
docker-compose logs

# View specific service logs
docker-compose logs springboot-app
docker-compose logs mysql
docker-compose logs nginx
```

## 📄 License

This project is open source and available under the [MIT License](LICENSE).