.PHONY: all build up down stop start restart logs status ps clean fclean re help

# Variables
COMPOSE_FILE := srcs/docker-compose.yml
COMPOSE_CMD := docker compose -f $(COMPOSE_FILE)

# Colors
GREEN := \033[0;32m
RED := \033[0;31m
YELLOW := \033[1;33m
NC := \033[0m

help:
	@echo "$(GREEN)=== Inception Project Makefile ===$(NC)"
	@echo ""
	@echo "$(YELLOW)Available targets:$(NC)"
	@echo "  make build      - Build all Docker images"
	@echo "  make up         - Start all containers"
	@echo "  make down       - Stop and remove all containers"
	@echo "  make stop       - Stop all containers (keep data)"
	@echo "  make start      - Start stopped containers"
	@echo "  make restart    - Restart all containers"
	@echo "  make status     - Show container status"
	@echo "  make ps         - Alias for status"
	@echo "  make logs       - Show live logs from all services"
	@echo "  make clean      - Remove containers and networks (keep volumes)"
	@echo "  make fclean     - Remove everything including volumes"
	@echo "  make re         - Clean rebuild and restart (fclean + build + up)"
	@echo ""

all: build up

build:
	@echo "$(GREEN)[build] Building Docker images...$(NC)"
	$(COMPOSE_CMD) build
	@echo "$(GREEN)[build] ✅ Build complete$(NC)"

up:
	@echo "$(GREEN)[up] Starting containers...$(NC)"
	$(COMPOSE_CMD) up -d
	@echo "$(GREEN)[up] ✅ Containers started$(NC)"
	@echo ""
	@echo "$(YELLOW)Services:$(NC)"
	@echo "  - MariaDB:  mariadb:3306 (internal)"
	@echo "  - WordPress: php-fpm:9000 (internal)"
	@echo "  - Nginx:     https://localhost:443"
	@echo ""

down:
	@echo "$(YELLOW)[down] Stopping and removing containers...$(NC)"
	$(COMPOSE_CMD) down
	@echo "$(GREEN)[down] ✅ Containers stopped and removed$(NC)"

stop:
	@echo "$(YELLOW)[stop] Stopping containers...$(NC)"
	$(COMPOSE_CMD) stop
	@echo "$(GREEN)[stop] ✅ Containers stopped$(NC)"

start:
	@echo "$(GREEN)[start] Starting containers...$(NC)"
	$(COMPOSE_CMD) start
	@echo "$(GREEN)[start] ✅ Containers started$(NC)"

restart: stop start
	@echo "$(GREEN)[restart] ✅ Containers restarted$(NC)"

status ps:
	@echo "$(GREEN)Container Status:$(NC)"
	@$(COMPOSE_CMD) ps
	@echo ""
	@echo "$(GREEN)Volume Status:$(NC)"
	@docker volume ls | grep inception || echo "No inception volumes found"

logs:
	@echo "$(GREEN)[logs] Showing live logs (Ctrl+C to exit)...$(NC)"
	$(COMPOSE_CMD) logs -f

clean:
	@echo "$(YELLOW)[clean] Removing containers and networks...$(NC)"
	$(COMPOSE_CMD) down
	@echo "$(GREEN)[clean] ✅ Cleaned$(NC)"

fclean: clean
	@echo "$(YELLOW)[fclean] Removing all volumes and data...$(NC)"
	@sudo rm -rf /home/edobele/data/db/* /home/edobele/data/db/.* 2>/dev/null || true
	@sudo rm -rf /home/edobele/data/wp/* /home/edobele/data/wp/.* 2>/dev/null || true
	@docker volume rm srcs_db_data srcs_wp_data 2>/dev/null || true
	@echo "$(GREEN)[fclean] ✅ Full clean complete$(NC)"

re: fclean build up
	@echo "$(GREEN)[re] ✅ Full rebuild and restart complete$(NC)"

.DEFAULT_GOAL := help
