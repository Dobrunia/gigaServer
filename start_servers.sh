#!/bin/bash

# Цвета для вывода
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Starting all servers...${NC}"

# Function to start server in new terminal
start_server() {
    local name=$1
    local port=$2
    local command=$3
    local dir=$4
    
    echo -e "${YELLOW}Starting $name server on port $port...${NC}"
    
    # Create temporary script for each server
    local script_name="/tmp/start_$(echo $name | tr '[:upper:]' '[:lower:]').sh"
    # Get absolute path to project
    local project_root="$(cd "$(dirname "$0")" && pwd)"
    
    cat > "$script_name" << EOF
#!/bin/bash
cd "$project_root/$dir"
echo -e "${GREEN}✅ $name server started on port $port${NC}"
echo -e "${BLUE}Command: $command${NC}"
echo "Press Ctrl+C to stop"
echo "----------------------------------------"
$command
EOF
    chmod +x "$script_name"
    
    # Start in new terminal (macOS)
    osascript -e "tell application \"Terminal\" to do script \"$script_name\""
}

# Start all servers
start_server "Perl" "3000" "perl app.pl" "servers/perl-mojolicious"
start_server "Rust" "3001" "cargo run" "servers/rust"  
start_server "Go" "3002" "go run ." "servers/go"

echo -e "${GREEN}🎉 All servers started!${NC}"
echo -e "${BLUE}Available servers:${NC}"
echo -e "  ${YELLOW}• Perl:${NC} http://127.0.0.1:3000"
echo -e "  ${YELLOW}• Rust:${NC} http://127.0.0.1:3001" 
echo -e "  ${YELLOW}• Go:${NC}   http://127.0.0.1:3002"
echo ""
echo -e "${BLUE}To stop servers, close the corresponding terminals${NC}"
