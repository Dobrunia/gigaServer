.PHONY: help start start-tmux stop clean

# Цвета
BLUE := \033[0;34m
GREEN := \033[0;32m
YELLOW := \033[1;33m
NC := \033[0m

help: ## Показать справку
	@echo "$(BLUE)🚀 Доступные команды:$(NC)"
	@echo ""
	@echo "$(YELLOW)Запуск серверов:$(NC)"
	@echo "  make start      - Запустить все серверы в отдельных терминалах"
	@echo "  make start-tmux - Запустить все серверы в tmux"
	@echo ""
	@echo "$(YELLOW)Управление:$(NC)"
	@echo "  make stop       - Остановить tmux сессию"
	@echo "  make clean      - Очистить временные файлы"
	@echo ""
	@echo "$(YELLOW)Отдельные серверы:$(NC)"
	@echo "  make perl       - Запустить только Perl сервер"
	@echo "  make rust       - Запустить только Rust сервер"
	@echo "  make go         - Запустить только Go сервер"

start: ## Запустить все серверы в отдельных терминалах
	@echo "$(BLUE)🚀 Запуск всех серверов...$(NC)"
	@./start_servers.sh

start-tmux: ## Запустить все серверы в tmux
	@echo "$(BLUE)🚀 Запуск всех серверов в tmux...$(NC)"
	@./start_servers_tmux.sh

stop: ## Остановить tmux сессию
	@echo "$(YELLOW)🛑 Остановка tmux сессии...$(NC)"
	@tmux kill-session -t servers 2>/dev/null || echo "Сессия не найдена"

clean: ## Очистить временные файлы
	@echo "$(YELLOW)🧹 Очистка временных файлов...$(NC)"
	@rm -f /tmp/start_*.sh

perl: ## Запустить только Perl сервер
	@echo "$(BLUE)🐪 Запуск Perl сервера...$(NC)"
	@cd servers/perl-mojolicious && perl app.pl

rust: ## Запустить только Rust сервер
	@echo "$(BLUE)🦀 Запуск Rust сервера...$(NC)"
	@cd servers/rust && cargo run

go: ## Запустить только Go сервер
	@echo "$(BLUE)🐹 Запуск Go сервера...$(NC)"
	@cd servers/go && go run .
