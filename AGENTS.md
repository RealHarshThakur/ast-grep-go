# Agent Instructions

## Project Structure

This project contains AST-grep rules for detecting Go mistakes.

```
go_mistakes_ast_grep/
├── rules/                   # Rule definitions
│   ├── 01-loop-var-capture.yml
│   └── 02-defer-in-loop.yml
├── rules_test/              # Test cases
│   ├── 01-loop-var-capture_test.go
│   └── 02-defer-in-loop_test.go
├── ast-grep.yml            # Main configuration
├── Makefile                # Build/test commands
└── AGENTS.md              # This file
```

## Important Notes

**No Go compiler errors or diagnostics in test files.** All `*_test.go` files must be syntactically valid and compile successfully with zero gopls and compiler errors/warnings. Every test function must either use the `testing.T` parameter or be a regular helper function, not a test function. Ensure all variables are used and there are no undefined references.

**Rule validation.** All `BadUsage_*` functions in test files must trigger ast-grep diagnostic warnings (visible in editor diagnostics). All `GoodUsage_*` functions must NOT trigger any diagnostics. Continue iterating on rule patterns until all test cases pass correctly.

## Creating a New Rule

### 1. Create Rule File
Place in `rules/` directory with naming convention: `NN-rule-name.yml`

Example: `rules/02-my-rule.yml`

**Register the rule in ast-grep.yml:** Add the new rule file to `ast-grep.yml` in the rules list so it will be picked up by `make test`:
```yaml
rules:
  - ./rules/01-loop-var-capture.yml
  - ./rules/02-my-rule.yml  # Add new rule here
```

**Required structure:**
```yaml
id: my-rule
language: go
message: "Clear, helpful error message"
severity: warning

rule:
  pattern: |
    your_ast_grep_pattern_here
```

**Note on severity:** Always use `severity: warning`. Do not use `error` or `hint` - keeping all rule severities consistent makes the linting output uniform and easier to manage.

### 2. Test the Pattern

**Using the agent's inline tester:**

Use `mcp__ast_grep__test_match_code_rule` to verify patterns work before integrating:
```yaml
mcp__ast_grep__test_match_code_rule:
  code: "your go code here"
  yaml: "your rule yaml"
```

Example test result (success):
- Returns JSON with match details, metavariables, and match ranges
- If no match: returns "No matches found"

**To verify rule works against test file:**
```bash
ast-grep scan rules_test/NN-rule-name_test.go -r rules/NN-rule-name.yml
```

Should show:
- All `BadUsage_*` functions flagged with rule ID
- All `GoodUsage_*` functions with no matches

**CLI test (after rule is in `rules/`):**
```bash
ast-grep scan test-file.go -r rules/
```

### 3. Create Test File
Place in `rules_test/` directory with naming convention: `NN-rule-name_test.go`

Example: `rules_test/02-my-rule_test.go`

**Structure:**
```go
package main

import (
	"fmt"
	"testing"
)

// BadUsage_DescriptiveCase should trigger the rule
func BadUsage_DescriptiveCase(t *testing.T) {
	// Code that SHOULD trigger the rule
	// BUG: explanatory comment
}

// BadUsage_AnotherBadCase should trigger the rule
func BadUsage_AnotherBadCase(t *testing.T) {
	// Another bad pattern
}

// GoodUsage_DescriptiveCase should NOT trigger the rule
func GoodUsage_DescriptiveCase(t *testing.T) {
	// Code that should NOT trigger the rule
	// OK: no issue here
}

// GoodUsage_AnotherGoodCase should NOT trigger the rule
func GoodUsage_AnotherGoodCase(t *testing.T) {
	// Another good pattern
}
```

**Naming conventions:**
- Test functions: `BadUsage_*` or `GoodUsage_*` followed by descriptive case name
- Comments above function: explain what should/shouldn't trigger
- Inline comments in code: mark bugs with `// BUG:` or `// OK:`
- **Ensure all function names in a test file are unique** - Go does not allow duplicate function names in the same package, even across different test files

## Pattern Syntax

Common wildcards:
- `$$_` - Match any single statement or expression
- `$$` - Match any multi-statement sequence  
- `$VAR` - Named capture (single token)
- `$$_` with specific keywords - Match that specific construct

Example patterns:
```yaml
# Simple defer in loop
for $$_ {
  defer $$_
}

# Goroutine capturing loop variable
for $I := range $XS {
  go func() { $$_ }()
}
```

## Testing Rules

### Manual test (CLI)
Test a specific rule against its test file:
```bash
ast-grep scan rules_test/02-my-rule_test.go -r rules/02-my-rule.yml
```

### Verify test cases work
After creating or updating a rule, always scan the test file and verify the output:
```bash
ast-grep scan rules_test/NN-rule-name_test.go -r rules/NN-rule-name.yml
```

**Important:** Check the output to ensure:
- All `BadUsage_*` functions trigger warnings or errors from the rule
- All `GoodUsage_*` functions produce NO diagnostics
- If BadUsage functions don't trigger, iterate on the rule pattern until they do

### Run all tests
```bash
make test
```

The test command scans all registered rules against their corresponding test files to verify patterns work correctly. Test files use function naming conventions (`BadUsage_*` and `GoodUsage_*`) to document expected behavior:
- All `BadUsage_*` functions should trigger rule warnings
- All `GoodUsage_*` functions should have NO warnings

### Lint all rules
```bash
make lint
```

## Amp CLI and Batch Thread Creation

**Important limitation:** Amp CLI execute mode (`amp -x`) is **not compatible with free mode**. Execute mode requires paid smart mode credits.

For batch thread creation workflows:
- Interactive approach: Use `amp` to manually create threads with `/mode free` and `/visibility private` per thread
- Batch approach: Use `amp threads new --visibility private` to create persistent threads, then `amp threads continue <thread-id> -x "prompt" --dangerously-allow-all` to populate them (requires smart mode credits)

The ast-grep MCP is already configured globally in `~/.config/amp/settings.json` and will be available in all thread modes.

## Naming Conventions

- **Rule files:** `rules/NN-descriptive-name.yml` (where NN is number 01, 02, etc.)
- **Test files:** `rules_test/NN-descriptive-name_test.go` (matching rule number)
- **Rule ID:** lowercase, hyphenated (e.g., `defer-in-loop`)

## Common AST Patterns (Go)

- `for_statement` - Any for loop
- `go_statement` - Goroutine launch
- `defer_statement` - Defer call
- `function_declaration` - Function definition
- `call_expression` - Function call

## Debugging

1. **Check pattern syntax:** Use `mcp__ast_grep__dump_syntax_tree` to see AST structure
2. **Test incrementally:** Start with simple patterns, add complexity
3. **Use stopBy: end** - When using `has` or `inside` rules with nested structures

Example debug:
```bash
ast-grep run --pattern "your_pattern_here" test-file.go
```

### YAML Pattern Literal Block Syntax Issue

**Problem:** Using the YAML literal block scalar syntax `|` (pipe) can cause patterns to fail silently in `ast-grep scan` with `-r` option, even though they work fine with `ast-grep run`.

**Example that FAILS:**
```yaml
rule:
  pattern: |
    for $_ := range $_ {
      func() { $$_ }()
    }
```

**Solution:** Remove the `|` and write the pattern directly. Newlines in YAML will be preserved:
```yaml
rule:
  pattern:
    for $_ := range $_ {
      func() { $$_ }()
    }
```

Or use `any:` with multiple pattern entries (preferred for multiple variations):
```yaml
rule:
  any:
    - pattern:
        for $_ := range $_ {
          func() { $$_ }()
        }
    - pattern:
        for $_ := range $_ {
          $$_
          func() { $$_ }()
        }
```

**Key insight:** When a rule works with `ast-grep run --pattern` but fails with `ast-grep scan -r rules/`, check if you're using `|` literal block scalar syntax - switch to direct YAML pattern assignment instead.

## Rule-Specific Instructions

### "Recover called outside a defer"

When asked to create a rule for detecting `recover()` calls outside of defer statements:

**Bad Example (should trigger rule):**
```go
// Calling recover() directly in a function body - ineffective
func Handler() {
	recover()  // BUG: recover() only works inside a defer
	// ... rest of code
}

// Calling recover() inside a goroutine without defer
func BadGoroutine() {
	go func() {
		recover()  // BUG: not in a defer
	}()
}
```

**Good Example (should NOT trigger rule):**
```go
// recover() correctly inside defer
func Handler() {
	defer func() {
		if r := recover(); r != nil {
			log.Printf("Recovered: %v", r)
		}
	}()
	// ... rest of code
}

// recover() inside defer in goroutine
func GoodGoroutine() {
	go func() {
		defer func() {
			if r := recover(); r != nil {
				log.Printf("Recovered: %v", r)
			}
		}()
	}()
}
```

The rule should detect calls to `recover()` that are NOT enclosed within a defer function literal.
