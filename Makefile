# Makefile for Library of Alexandria

# Default environment
ENV ?= dev

# Docker compose files
COMPOSE_FILE = docker-compose.yml
COMPOSE_DEV_FILE = docker-compose.dev.yml

# Colors for output
GREEN = \033[0;32m
YELLOW = \033[1;33m
RED = \033[0;31m
NC = \033[0m # No Color

.PHONY: help build up down logs test clean dev-up dev-down setup

help: ## Show this help message
	@echo "Library of Alexandria - Development Commands"
	@echo ""
	@echo "Usage: make [target]"
	@echo ""
	@echo "Targets:"
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "  $(GREEN)%-15s$(NC) %s\n", $$1, $$2}'

setup: ## Initial setup - create .env file and build images
	@echo "$(YELLOW)Setting up Library of Alexandria...$(NC)"
	@if [ ! -f .env ]; then \
		cp .env.template .env; \
		echo "$(GREEN)Created .env file from template. Please edit it with your values.$(NC)"; \
	else \
		echo "$(YELLOW).env file already exists$(NC)"; \
	fi
	@make build

build: ## Build Docker images
	@echo "$(YELLOW)Building Docker images...$(NC)"
	@docker-compose -f $(COMPOSE_FILE) build
	@echo "$(GREEN)Build complete!$(NC)"

up: ## Start production environment
	@echo "$(YELLOW)Starting production environment...$(NC)"
	@docker-compose -f $(COMPOSE_FILE) up -d
	@echo "$(GREEN)Production environment started!$(NC)"
	@echo "Frontend: http://localhost:8080"
	@echo "Backend: http://localhost:5050"
	@echo "PHPMyAdmin: http://localhost:8081"

down: ## Stop production environment
	@echo "$(YELLOW)Stopping production environment...$(NC)"
	@docker-compose -f $(COMPOSE_FILE) down
	@echo "$(GREEN)Production environment stopped!$(NC)"

dev-up: ## Start development environment with hot reload
	@echo "$(YELLOW)Starting development environment...$(NC)"
	@docker-compose -f $(COMPOSE_DEV_FILE) up -d
	@echo "$(GREEN)Development environment started!$(NC)"
	@echo "Frontend: http://localhost:8080"
	@echo "Backend: http://localhost:5050 (Debug: 5005)"
	@echo "PHPMyAdmin: http://localhost:8082"

dev-down: ## Stop development environment
	@echo "$(YELLOW)Stopping development environment...$(NC)"
	@docker-compose -f $(COMPOSE_DEV_FILE) down
	@echo "$(GREEN)Development environment stopped!$(NC)"

logs: ## View logs
	@docker-compose -f $(COMPOSE_FILE) logs -f

dev-logs: ## View development logs
	@docker-compose -f $(COMPOSE_DEV_FILE) logs -f

test: ## Run tests
	@echo "$(YELLOW)Running tests...$(NC)"
	@cd Backend && ./mvnw test
	@echo "$(GREEN)Tests completed!$(NC)"

test-integration: ## Run integration tests with Docker
	@echo "$(YELLOW)Running integration tests...$(NC)"
	@docker-compose -f docker-compose.test.yml up --abort-on-container-exit
	@docker-compose -f docker-compose.test.yml down
	@echo "$(GREEN)Integration tests completed!$(NC)"

clean: ## Clean up Docker resources
	@echo "$(YELLOW)Cleaning up Docker resources...$(NC)"
	@docker-compose -f $(COMPOSE_FILE) down -v --remove-orphans
	@docker-compose -f $(COMPOSE_DEV_FILE) down -v --remove-orphans
	@docker system prune -f
	@echo "$(GREEN)Cleanup complete!$(NC)"

restart: down up ## Restart production environment

dev-restart: dev-down dev-up ## Restart development environment

status: ## Show service status
	@echo "$(YELLOW)Service Status:$(NC)"
	@docker-compose -f $(COMPOSE_FILE) ps

dev-status: ## Show development service status
	@echo "$(YELLOW)Development Service Status:$(NC)"
	@docker-compose -f $(COMPOSE_DEV_FILE) ps

shell-backend: ## Open shell in backend container
	@docker-compose -f $(COMPOSE_FILE) exec springboot-app sh

shell-db: ## Open MySQL shell
	@docker-compose -f $(COMPOSE_FILE) exec mysql mysql -u root -p

backup-db: ## Backup database
	@echo "$(YELLOW)Creating database backup...$(NC)"
	@docker-compose -f $(COMPOSE_FILE) exec mysql mysqldump -u root -p librarydb > backup_$(shell date +%Y%m%d_%H%M%S).sql
	@echo "$(GREEN)Database backup created!$(NC)"

install: setup ## Alias for setup

start: up ## Alias for up

stop: down ## Alias for down