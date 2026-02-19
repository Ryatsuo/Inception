COMPOSE_FILE := srcs/docker-compose.yml
COMPOSE_CMD := docker compose -f $(COMPOSE_FILE)

GREEN := \033[0;32m
YELLOW := \033[1;33m
NC := \033[0m

build:
	@echo "$(GREEN)[build] Building Docker images...$(NC)"
	$(COMPOSE_CMD) build

up:
	@echo "$(GREEN)[up] Starting containers...$(NC)"
	$(COMPOSE_CMD) up -d

down:
	@echo "$(YELLOW)[down] Stopping and removing containers...$(NC)"
	$(COMPOSE_CMD) down

logs:
	$(COMPOSE_CMD) logs -f

status:
	@$(COMPOSE_CMD) ps

fclean: down
	@echo "$(YELLOW)[fclean] Removing all volumes and data...$(NC)"
	@sudo rm -rf /home/edobele/data/db/* /home/edobele/data/db/.* 2>/dev/null || true
	@sudo rm -rf /home/edobele/data/wp/* /home/edobele/data/wp/.* 2>/dev/null || true
	@docker volume rm srcs_db_data srcs_wp_data 2>/dev/null || true

re: fclean build up

help:
	@echo "$(GREEN)Inception Project Makefile$(NC)"
	@echo ""
	@echo "$(YELLOW)Available targets:$(NC)"
	@echo "  make build      - Build all Docker images"
	@echo "  make up         - Start all containers"
	@echo "  make down       - Stop and remove all containers"
	@echo "  make logs       - Show live logs from all services"
	@echo "  make status     - Show container status"
	@echo "  make fclean     - Remove everything including volumes"
	@echo "  make re         - Clean rebuild and restart (fclean + build + up)"
	@echo ""

.DEFAULT_GOAL := help

.PHONY: build up down logs status fclean re help
