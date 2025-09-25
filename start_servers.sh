#!/bin/bash

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Запуск всех серверов...${NC}"

# Функция для запуска сервера в новом терминале
start_server() {
    local name=$1
    local port=$2
    local command=$3
    local dir=$4
    
    echo -e "${YELLOW}Запуск $name сервера на порту $port...${NC}"
    
    # Создаем временный скрипт для каждого сервера
    local script_name="/tmp/start_$(echo $name | tr '[:upper:]' '[:lower:]').sh"
    # Получаем абсолютный путь к проекту
    local project_root="$(cd "$(dirname "$0")" && pwd)"
    
    cat > "$script_name" << EOF
#!/bin/bash
cd "$project_root/$dir"
echo -e "${GREEN}✅ $name сервер запущен на порту $port${NC}"
echo -e "${BLUE}Команда: $command${NC}"
echo "Нажмите Ctrl+C для остановки"
echo "----------------------------------------"
$command
EOF
    chmod +x "$script_name"
    
    # Запускаем в новом терминале (macOS)
    osascript -e "tell application \"Terminal\" to do script \"$script_name\""
}

# Запускаем все серверы
start_server "Perl" "3000" "perl app.pl" "servers/perl-mojolicious"
start_server "Rust" "3001" "cargo run" "servers/rust"  
start_server "Go" "3002" "go run ." "servers/go"

echo -e "${GREEN}🎉 Все серверы запущены!${NC}"
echo -e "${BLUE}Доступные серверы:${NC}"
echo -e "  ${YELLOW}• Perl:${NC} http://127.0.0.1:3000"
echo -e "  ${YELLOW}• Rust:${NC} http://127.0.0.1:3001" 
echo -e "  ${YELLOW}• Go:${NC}   http://127.0.0.1:3002"
echo ""
echo -e "${BLUE}Для остановки серверов закройте соответствующие терминалы${NC}"
