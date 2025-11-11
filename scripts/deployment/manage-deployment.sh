#!/bin/bash

# ============================================================================
# Kubernetes Deployment Management Script
# ============================================================================
# Central management for voting app deployment
# Run: ./manage-deployment.sh [command]
# ============================================================================

set -e

# Color codes
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m' # No Color

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Show usage
usage() {
    echo -e "${BOLD}Usage:${NC} ./manage-deployment.sh [command]"
    echo ""
    echo -e "${BOLD}Commands:${NC}"
    echo "  start      - Deploy application to cluster"
    echo "  stop       - Stop and delete all resources"
    echo "  status     - Check deployment status"
    echo "  validate   - Run validation tests"
    echo "  restart    - Stop and start (full redeploy)"
    echo "  help       - Show this help message"
    echo ""
    echo -e "${BOLD}Examples:${NC}"
    echo "  ./manage-deployment.sh start"
    echo "  ./manage-deployment.sh status"
    echo "  ./manage-deployment.sh restart"
    echo ""
}

# If no command provided, show help
if [ $# -eq 0 ]; then
    usage
    exit 0
fi

case "$1" in
    start)
        echo -e "${BLUE}🚀 Starting deployment...${NC}"
        $SCRIPT_DIR/start-deployment.sh
        ;;
    
    stop)
        echo -e "${BLUE}🛑 Stopping deployment...${NC}"
        $SCRIPT_DIR/stop-deployment.sh
        ;;
    
    status)
        echo -e "${BLUE}📊 Checking status...${NC}"
        $SCRIPT_DIR/status-deployment.sh
        ;;
    
    validate)
        echo -e "${BLUE}🧪 Running validation tests...${NC}"
        $SCRIPT_DIR/validate-deployment.sh
        ;;
    
    restart)
        echo -e "${YELLOW}⚠️  Restarting deployment (this will delete all resources)${NC}"
        read -p "Continue? (yes/no): " confirm
        if [ "$confirm" = "yes" ]; then
            $SCRIPT_DIR/stop-deployment.sh
            sleep 5
            $SCRIPT_DIR/start-deployment.sh
        else
            echo "Cancelled"
        fi
        ;;
    
    help)
        usage
        ;;
    
    *)
        echo -e "${RED}❌ Unknown command: $1${NC}"
        echo ""
        usage
        exit 1
        ;;
esac
