#!/bin/bash

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Запуск всех серверов в tmux...${NC}"

# Проверяем наличие tmux
if ! command -v tmux &> /dev/null; then
    echo -e "${RED}❌ tmux не установлен. Установите: brew install tmux${NC}"
    exit 1
fi

# Создаем новую tmux сессию
tmux new-session -d -s servers

# Создаем окна для каждого сервера
tmux new-window -t servers:1 -n "Perl" -c "$(dirname "$0")/servers/perl-mojolicious"
tmux new-window -t servers:2 -n "Rust" -c "$(dirname "$0")/servers/rust"  
tmux new-window -t servers:3 -n "Go" -c "$(dirname "$0")/servers/go"

# Запускаем серверы
tmux send-keys -t servers:1 "echo '🐪 Perl сервер на порту 3000' && perl app.pl" Enter
tmux send-keys -t servers:2 "echo '🦀 Rust сервер на порту 3001' && cargo run" Enter
tmux send-keys -t servers:3 "echo '🐹 Go сервер на порту 3002' && go run ." Enter

echo -e "${GREEN}🎉 Все серверы запущены в tmux!${NC}"
echo -e "${BLUE}Доступные серверы:${NC}"
echo -e "  ${YELLOW}• Perl:${NC} http://127.0.0.1:3000"
echo -e "  ${YELLOW}• Rust:${NC} http://127.0.0.1:3001" 
echo -e "  ${YELLOW}• Go:${NC}   http://127.0.0.1:3002"
echo ""
echo -e "${BLUE}Управление tmux:${NC}"
echo -e "  ${YELLOW}• Подключиться:${NC} tmux attach -t servers"
echo -e "  ${YELLOW}• Переключение окон:${NC} Ctrl+b + номер окна (1,2,3)"
echo -e "  ${YELLOW}• Остановить все:${NC} tmux kill-session -t servers"
echo -e "  ${YELLOW}• Отключиться:${NC} Ctrl+b + d"

# Подключаемся к tmux
tmux attach -t servers
