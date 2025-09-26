#!/bin/bash

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Starting all servers in tmux...${NC}"

# Check if tmux is available
if ! command -v tmux &> /dev/null; then
    echo -e "${RED}❌ tmux not installed. Install: brew install tmux${NC}"
    exit 1
fi

# Create new tmux session
tmux new-session -d -s servers

# Create windows for each server
tmux new-window -t servers:1 -n "Perl" -c "$(dirname "$0")/servers/perl-mojolicious"
tmux new-window -t servers:2 -n "Rust" -c "$(dirname "$0")/servers/rust"  
tmux new-window -t servers:3 -n "Go" -c "$(dirname "$0")/servers/go"

# Start servers
tmux send-keys -t servers:1 "echo '🐪 Perl server on port 3000' && perl app.pl" Enter
tmux send-keys -t servers:2 "echo '🦀 Rust server on port 3001' && cargo run" Enter
tmux send-keys -t servers:3 "echo '🐹 Go server on port 3002' && go run ." Enter

echo -e "${GREEN}🎉 All servers started in tmux!${NC}"
echo -e "${BLUE}Available servers:${NC}"
echo -e "  ${YELLOW}• Perl:${NC} http://127.0.0.1:3000"
echo -e "  ${YELLOW}• Rust:${NC} http://127.0.0.1:3001" 
echo -e "  ${YELLOW}• Go:${NC}   http://127.0.0.1:3002"
echo ""
echo -e "${BLUE}tmux management:${NC}"
echo -e "  ${YELLOW}• Attach:${NC} tmux attach -t servers"
echo -e "  ${YELLOW}• Switch windows:${NC} Ctrl+b + window number (1,2,3)"
echo -e "  ${YELLOW}• Stop all:${NC} tmux kill-session -t servers"
echo -e "  ${YELLOW}• Detach:${NC} Ctrl+b + d"

# Attach to tmux
tmux attach -t servers
