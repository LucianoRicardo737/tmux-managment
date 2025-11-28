#!/usr/bin/env bash

# Advanced Demo for tmux Session Switcher v2.0
# This script creates demo sessions with hydration scripts to showcase all features

set -e

CYAN="\033[0;36m"
GREEN="\033[0;32m"
YELLOW="\033[1;33m"
RED="\033[0;31m"
BOLD="\033[1m"
RESET="\033[0m"

# Create temporary demo directories
DEMO_DIR="/tmp/tmux-switcher-demo"
rm -rf "$DEMO_DIR"
mkdir -p "$DEMO_DIR"/{project1,project2,project3,project4,project5}

echo -e "${CYAN}${BOLD}"
echo "╔════════════════════════════════════════════════════════╗"
echo "║   tmux Session Switcher v2.0 - Advanced Demo          ║"
echo "╚════════════════════════════════════════════════════════╝"
echo -e "${RESET}"

echo -e "${CYAN}This demo will:${RESET}"
echo "  1. Create 5 demo projects with different structures"
echo "  2. Add hydration scripts to each project"
echo "  3. Create tmux sessions for each project"
echo "  4. Demonstrate all v2.0 features"
echo ""
echo -e "${YELLOW}Press Enter to continue...${RESET}"
read

# Project 1: Web Frontend (React/Node)
echo -e "${CYAN}Creating Project 1: Web Frontend...${RESET}"
cd "$DEMO_DIR/project1"
cat > package.json << 'EOF'
{
  "name": "web-frontend",
  "version": "1.0.0",
  "scripts": {
    "dev": "echo 'Starting dev server on port 3000...'"
  }
}
EOF

cat > .tmux-sessionizer << 'EOF'
#!/bin/bash
# Frontend project hydration
tmux rename-window "editor"
tmux send-keys "echo 'Frontend project loaded!'" C-m
tmux send-keys "echo 'Files: package.json, src/...'" C-m
tmux new-window -n "dev-server"
tmux send-keys "echo 'Run: npm run dev'" C-m
tmux new-window -n "tests"
tmux send-keys "echo 'Run: npm test'" C-m
tmux new-window -n "git"
tmux send-keys "echo 'Git status and commits'" C-m
tmux select-window -t 1
EOF
chmod +x .tmux-sessionizer

# Project 2: Backend API
echo -e "${CYAN}Creating Project 2: Backend API...${RESET}"
cd "$DEMO_DIR/project2"
cat > Dockerfile << 'EOF'
FROM node:18
WORKDIR /app
COPY package*.json ./
RUN npm install
COPY . .
EXPOSE 8080
CMD ["node", "server.js"]
EOF

cat > .tmux-sessionizer << 'EOF'
#!/bin/bash
# Backend API hydration
tmux rename-window "editor"
tmux send-keys "echo 'Backend API project loaded!'" C-m
tmux send-keys "echo 'Files: Dockerfile, server.js, ...'" C-m
tmux new-window -n "api-server"
tmux send-keys "echo 'Run: node server.js'" C-m
tmux new-window -n "docker"
tmux send-keys "echo 'Docker commands here'" C-m
tmux send-keys "docker ps" C-m
tmux new-window -n "logs"
tmux send-keys "echo 'Server logs...'" C-m
tmux select-window -t 1
EOF
chmod +x .tmux-sessionizer

# Project 3: DevOps Infrastructure
echo -e "${CYAN}Creating Project 3: DevOps...${RESET}"
cd "$DEMO_DIR/project3"
mkdir -p terraform ansible
cat > terraform/main.tf << 'EOF'
# Terraform configuration
resource "example" "demo" {
  name = "demo"
}
EOF

cat > .tmux-sessionizer << 'EOF'
#!/bin/bash
# DevOps hydration
tmux rename-window "editor"
tmux send-keys "echo 'DevOps project loaded!'" C-m
tmux send-keys "echo 'Infrastructure as Code'" C-m
tmux new-window -n "terraform"
tmux send-keys "cd terraform" C-m
tmux send-keys "echo 'Run: terraform plan'" C-m
tmux new-window -n "kubectl"
tmux send-keys "echo 'Kubernetes commands'" C-m
tmux send-keys "kubectl get pods" C-m
tmux select-window -t 1
EOF
chmod +x .tmux-sessionizer

# Project 4: Machine Learning
echo -e "${CYAN}Creating Project 4: ML/AI...${RESET}"
cd "$DEMO_DIR/project4"
cat > requirements.txt << 'EOF'
numpy
pandas
scikit-learn
tensorflow
EOF

cat > .tmux-sessionizer << 'EOF'
#!/bin/bash
# ML project hydration
tmux rename-window "jupyter"
tmux send-keys "echo 'ML/AI project loaded!'" C-m
tmux send-keys "echo 'Start: jupyter notebook'" C-m
tmux new-window -n "training"
tmux send-keys "echo 'Model training terminal'" C-m
tmux new-window -n "tensorboard"
tmux send-keys "echo 'Tensorboard visualization'" C-m
tmux select-window -t 1
EOF
chmod +x .tmux-sessionizer

# Project 5: Mobile App
echo -e "${CYAN}Creating Project 5: Mobile App...${RESET}"
cd "$DEMO_DIR/project5"
cat > package.json << 'EOF'
{
  "name": "mobile-app",
  "version": "1.0.0",
  "scripts": {
    "android": "react-native run-android",
    "ios": "react-native run-ios"
  }
}
EOF

cat > .tmux-sessionizer << 'EOF'
#!/bin/bash
# Mobile app hydration
tmux rename-window "editor"
tmux send-keys "echo 'Mobile app project loaded!'" C-m
tmux new-window -n "android"
tmux send-keys "echo 'Android emulator'" C-m
tmux send-keys "echo 'Run: npm run android'" C-m
tmux new-window -n "ios"
tmux send-keys "echo 'iOS simulator'" C-m
tmux send-keys "echo 'Run: npm run ios'" C-m
tmux new-window -n "logs"
tmux send-keys "echo 'Device logs'" C-m
tmux select-window -t 1
EOF
chmod +x .tmux-sessionizer

# Create sessions
echo ""
echo -e "${CYAN}Creating tmux sessions...${RESET}"

# Kill existing demo sessions if they exist
for session in web-frontend backend-api devops ml-ai mobile-app; do
    tmux kill-session -t "$session" 2>/dev/null || true
done

# Create sessions with hydration
echo -e "${GREEN}Creating session: web-frontend${RESET}"
tmux new-session -d -s "web-frontend" -c "$DEMO_DIR/project1"
if [ -f "$DEMO_DIR/project1/.tmux-sessionizer" ]; then
    tmux send-keys -t "web-frontend" "source $DEMO_DIR/project1/.tmux-sessionizer" C-m
fi

echo -e "${GREEN}Creating session: backend-api${RESET}"
tmux new-session -d -s "backend-api" -c "$DEMO_DIR/project2"
if [ -f "$DEMO_DIR/project2/.tmux-sessionizer" ]; then
    tmux send-keys -t "backend-api" "source $DEMO_DIR/project2/.tmux-sessionizer" C-m
fi

echo -e "${GREEN}Creating session: devops${RESET}"
tmux new-session -d -s "devops" -c "$DEMO_DIR/project3"
if [ -f "$DEMO_DIR/project3/.tmux-sessionizer" ]; then
    tmux send-keys -t "devops" "source $DEMO_DIR/project3/.tmux-sessionizer" C-m
fi

echo -e "${GREEN}Creating session: ml-ai${RESET}"
tmux new-session -d -s "ml-ai" -c "$DEMO_DIR/project4"
if [ -f "$DEMO_DIR/project4/.tmux-sessionizer" ]; then
    tmux send-keys -t "ml-ai" "source $DEMO_DIR/project4/.tmux-sessionizer" C-m
fi

echo -e "${GREEN}Creating session: mobile-app${RESET}"
tmux new-session -d -s "mobile-app" -c "$DEMO_DIR/project5"
if [ -f "$DEMO_DIR/project5/.tmux-sessionizer" ]; then
    tmux send-keys -t "mobile-app" "source $DEMO_DIR/project5/.tmux-sessionizer" C-m
fi

echo ""
echo -e "${GREEN}${BOLD}✓ Demo sessions created successfully!${RESET}"
echo ""
echo -e "${CYAN}${BOLD}Demo Sessions:${RESET}"
tmux list-sessions | while read line; do
    echo -e "  ${GREEN}●${RESET} $line"
done

echo ""
echo -e "${CYAN}${BOLD}Now try these features:${RESET}"
echo ""
echo -e "${YELLOW}1. Popup Switcher (Alt+a or Prefix+Space):${RESET}"
echo "   - Press Alt+a to see the popup"
echo "   - Press 1-5 to quickly switch between sessions"
echo "   - Press D to search for more projects"
echo "   - Press Q to close"
echo "   - ${CYAN}Note: Alt+Tab doesn't work (captured by system)${RESET}"
echo ""
echo -e "${YELLOW}2. FZF Selector (Alt+s):${RESET}"
echo "   - Press Alt+s to open the full FZF interface"
echo "   - See preview of windows on the right"
echo "   - Use arrows to navigate"
echo "   - Press Ctrl+x to delete a session"
echo "   - Press Ctrl+r to reload"
echo ""
echo -e "${YELLOW}3. Directory Search (Alt+d):${RESET}"
echo "   - Press Alt+d to search for projects"
echo "   - Navigate to $DEMO_DIR to see demo projects"
echo "   - Select a project to create a new session"
echo "   - Hydration scripts will run automatically"
echo ""
echo -e "${YELLOW}4. Cycle Sessions (Alt+n / Alt+p):${RESET}"
echo "   - Press Alt+n for next session"
echo "   - Press Alt+p for previous session"
echo ""
echo -e "${YELLOW}5. Session Commands (requires config):${RESET}"
echo "   - Set up TS_SESSION_COMMANDS in ~/.config/tmux-sessionizer/tmux-sessionizer.conf"
echo "   - Run: tmux-session-switcher.sh -s 0"
echo "   - Try --vsplit and --hsplit flags"
echo ""
echo -e "${CYAN}${BOLD}Test Scenarios:${RESET}"
echo ""
echo "  ${BOLD}Scenario 1: Quick Switching${RESET}"
echo "    Alt+a → Press 2 → Instantly switch to backend-api"
echo ""
echo "  ${BOLD}Scenario 2: Explore Windows${RESET}"
echo "    Alt+s → Navigate to ml-ai → See all windows in preview"
echo ""
echo "  ${BOLD}Scenario 3: Create New Session${RESET}"
echo "    Alt+d → Navigate to any demo project → See hydration in action"
echo ""
echo "  ${BOLD}Scenario 4: Cleanup${RESET}"
echo "    Alt+s → Navigate to old session → Ctrl+x to delete"
echo ""
echo -e "${GREEN}${BOLD}Attach to a session to start testing:${RESET}"
echo -e "  ${CYAN}tmux attach -t web-frontend${RESET}"
echo ""
echo -e "${YELLOW}To clean up demo:${RESET}"
echo -e "  ${CYAN}make clean${RESET}  or  ${CYAN}./demo-advanced.sh --clean${RESET}"
echo ""
echo -e "${YELLOW}Demo projects location:${RESET}"
echo -e "  ${CYAN}$DEMO_DIR${RESET}"
echo ""
echo -e "${GREEN}Happy testing! 🚀${RESET}"

# Cleanup function
if [ "$1" = "--clean" ]; then
    echo -e "${YELLOW}Cleaning up demo...${RESET}"
    for session in web-frontend backend-api devops ml-ai mobile-app; do
        tmux kill-session -t "$session" 2>/dev/null && echo -e "  ${GREEN}✓${RESET} Killed session: $session" || true
    done
    rm -rf "$DEMO_DIR" && echo -e "  ${GREEN}✓${RESET} Removed demo directory"
    echo -e "${GREEN}Cleanup complete!${RESET}"
fi
