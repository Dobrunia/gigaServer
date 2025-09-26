.PHONY: help start start-tmux stop clean

help: ## Show help
	@echo "Available commands:"
	@echo ""
	@echo "Start servers:"
	@echo "  make start      - Start all servers in separate terminals"
	@echo "  make start-tmux - Start all servers in tmux"
	@echo ""
	@echo "Management:"
	@echo "  make stop       - Stop tmux session"
	@echo "  make clean      - Clean temporary files"
	@echo ""
	@echo "Individual servers:"
	@echo "  make perl       - Start only Perl server"
	@echo "  make rust       - Start only Rust server"
	@echo "  make go         - Start only Go server"

start: ## Start all servers in separate terminals
	@echo "Starting all servers..."
	@./start_servers.sh

start-tmux: ## Start all servers in tmux
	@echo "Starting all servers in tmux..."
	@./start_servers_tmux.sh

stop: ## Stop tmux session
	@echo "Stopping tmux session..."
	@tmux kill-session -t servers 2>/dev/null || echo "Session not found"

clean: ## Clean temporary files
	@echo "Cleaning temporary files..."
	@rm -f /tmp/start_*.sh

perl: ## Start only Perl server
	@echo "Starting Perl server..."
	@cd servers/perl-mojolicious && perl app.pl

rust: ## Start only Rust server
	@echo "Starting Rust server..."
	@cd servers/rust && cargo run

go: ## Start only Go server
	@echo "Starting Go server..."
	@cd servers/go && go run .
