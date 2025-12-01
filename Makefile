.PHONY: test lint help

test:
	@echo "Running rule tests..."
	@failed_rules=""; \
	for rule in rules_test/*_test.go; do \
		rule_base=$$(basename $$rule _test.go); \
		output=$$(ast-grep scan $$rule -r rules/$$rule_base.yml 2>&1); \
		if [ -z "$$output" ]; then \
			echo "✗ $$rule_base"; \
			failed_rules="$$failed_rules $$rule_base"; \
		else \
			echo "✓ $$rule_base"; \
		fi; \
	done; \
	if [ -n "$$failed_rules" ]; then \
		echo ""; \
		echo "FAILED - Rules did not detect violations:$$failed_rules"; \
		exit 1; \
	else \
		echo ""; \
		echo "All tests passed"; \
	fi

lint:
	@echo "Linting rules..."
	ast-grep scan

help:
	@echo "Available commands:"
	@echo "  make test   - Run rule tests with ast-grep"
	@echo "  make lint   - Lint rules with ast-grep"
	@echo "  make help   - Show this help message"
