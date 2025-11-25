.PHONY: help install uninstall test demo demo-advanced clean clean-all

help:
	@echo "tmux Session Switcher v2.0 - Available commands:"
	@echo ""
	@echo "  make install        - Install the session switcher"
	@echo "  make uninstall      - Remove the session switcher"
	@echo "  make test           - Test the script"
	@echo "  make demo           - Create basic demo sessions"
	@echo "  make demo-advanced  - Create advanced demo with hydration scripts"
	@echo "  make clean          - Remove demo sessions"
	@echo "  make clean-all      - Remove all demo sessions and files"
	@echo ""

install:
	@./install.sh

uninstall:
	@echo "Removing tmux-session-switcher..."
	@rm -f ~/.local/bin/tmux-session-switcher.sh
	@echo "Removed script from ~/.local/bin/"
	@echo ""
	@echo "Note: Please manually remove the configuration from ~/.tmux.conf"
	@echo "Look for lines containing 'tmux-session-switcher'"

test:
	@if [ -z "$$TMUX" ]; then \
		echo "Error: Must be run from within tmux"; \
		exit 1; \
	fi
	@echo "Testing session switcher..."
	@./tmux-session-switcher.sh menu
	@echo "Test completed!"

demo:
	@if [ -z "$$TMUX" ]; then \
		echo "Error: Must be run from within tmux"; \
		exit 1; \
	fi
	@./demo.sh

demo-advanced:
	@./demo-advanced.sh

clean:
	@echo "Removing basic demo sessions..."
	@tmux kill-session -t development 2>/dev/null || true
	@tmux kill-session -t frontend 2>/dev/null || true
	@tmux kill-session -t backend 2>/dev/null || true
	@tmux kill-session -t devops 2>/dev/null || true
	@tmux kill-session -t testing 2>/dev/null || true
	@echo "Basic demo sessions removed!"

clean-all:
	@echo "Removing all demo sessions and files..."
	@./demo-advanced.sh --clean
	@tmux kill-session -t development 2>/dev/null || true
	@tmux kill-session -t frontend 2>/dev/null || true
	@tmux kill-session -t backend 2>/dev/null || true
	@tmux kill-session -t devops 2>/dev/null || true
	@tmux kill-session -t testing 2>/dev/null || true
	@echo "All demo sessions and files removed!"
