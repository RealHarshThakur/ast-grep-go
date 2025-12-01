# ast-grep Go Mistakes Linter

A comprehensive AST-grep linting rule set for detecting common Go programming mistakes and anti-patterns. This project provides static analysis rules that catch problematic code before it reaches production.

## Overview

This project implements **11 detection rules** for Go mistakes using [ast-grep](https://ast-grep.github.io/), a powerful AST-based code search and linting tool. Each rule is defined as a YAML configuration file that describes a pattern to match, and includes comprehensive test cases to verify correctness.

## What We're Building

### 1. **AST-grep Rules**

AST-grep is a code pattern matcher that understands the Abstract Syntax Tree (AST) of your code. Instead of simple regex, it matches structural patterns.

Example rule (`01-loop-var-capture.yml`):
```yaml
id: loop-var-capture
language: go
message: "Loop variable captured by goroutine; pass it as an argument or shadow it."
severity: warning
rule:
  pattern: |
    for $I := range $XS {
      go func() { $$_ }()
    }
```

This catches the classic Go mistake of capturing loop variables in goroutines without passing them as arguments.


## Project Structure

```
ast-grep-go/
├── rules/                      # AST-grep rule definitions
│   ├── 01-loop-var-capture.yml
│   ├── 02-defer-in-loop.yml
│   └── ... (9 more rules)
├── rules_test/                 # Test cases for each rule
│   ├── 01-loop-var-capture_test.go
│   ├── 02-defer-in-loop_test.go
│   └── ... (9 more test files)
├── ast-grep.yml               # Main configuration (registers all rules)
├── Makefile                   # Commands for testing and linting
├── AGENTS.md                  # Developer instructions
└── README.md                  # This file
```

## How to Use

### Prerequisites

Install ast-grep:
```bash
npm install -g @ast-grep/cli
# or
brew install ast-grep  # macOS
```

### Run Tests

Verify all rules detect violations correctly:
```bash
make test
```

This scans each rule's test file and ensures:
- All `BadUsage_*` functions trigger the rule warning
- All `GoodUsage_*` functions do NOT trigger any warnings

### Lint Your Go Code

Scan Go files for violations:
```bash
ast-grep scan your-file.go -r rules/
# or scan entire directory
ast-grep scan ./src -r rules/
```

Output shows file, line, and rule ID for each violation:
```
rules_test/01-loop-var-capture_test.go:8:6: loop-var-capture
  8 │	for i := range items {
  9 │		go func() {
  | ^^^^^^^^^^^^^^
  10 │		}()
  11 │	}
  Pattern ID: loop-var-capture
  Message: Loop variable captured by goroutine; pass it as an argument or shadow it.
```

## AST-grep CLI

### Key Commands

```bash
# Scan files against rules
ast-grep scan <path> -r <rules-directory>

# Run a single rule
ast-grep scan file.go -r rules/01-loop-var-capture.yml

# Run with pattern directly
ast-grep run --pattern "for range" file.go

# Help
ast-grep --help
```

### Pattern Syntax

AST-grep patterns use wildcards to match code structure:

| Pattern | Meaning |
|---------|---------|
| `$VAR` | Named capture (single token) |
| `$$_` | Match any single statement or expression |
| `$$` | Match any multi-statement sequence |

Example:
```yaml
# Matches: for X := range Y { ... any code ... go func() { ... any code ... }() ... }
for $I := range $XS {
  $$_
  go func() { $$_ }()
  $$_
}
```

## MCP Integration

This project uses **Model Context Protocol (MCP)** via Amp, enabling AI-assisted code analysis and rule creation.

### What's Available in Amp

When working in Amp with this codebase:

1. **ast-grep MCP** - Configured globally in `~/.config/amp/settings.json`
   - `mcp__ast_grep__find_code` - Find code matching patterns
   - `mcp__ast_grep__test_match_code_rule` - Test rules before deployment
   - `mcp__ast_grep__dump_syntax_tree` - Debug AST structure

2. **Documentation Search** - Query project docs and AST-grep documentation
3. **Free Mode** - Free usage supported by advertisements (execute mode requires paid credits)

### Example MCP Usage in Amp

Test a new rule pattern:
```
mcp__ast_grep__test_match_code_rule:
  code: "for i := range items { go func() { print(i) }() }"
  yaml: "id: test-rule\nlanguage: go\nrule:\n  pattern: for $_ := range $_ { go func() { $$_ }() }"
```

Find code matching a pattern:
```
mcp__ast_grep__find_code(pattern="defer $$_", project_folder="/path/to/code")
```

## Creating New Rules

### 1. Define Rule (in `rules/NN-rule-name.yml`)

```yaml
id: rule-id
language: go
message: "Clear description of what's wrong"
severity: warning

rule:
  pattern: |
    your_pattern_here
```

### 2. Create Tests (in `rules_test/NN-rule-name_test.go`)

```go
package main

import "testing"

// BadUsage_Case1 should trigger the rule
func BadUsage_Case1(t *testing.T) {
  // Code that SHOULD trigger the rule
  // BUG: explanatory comment
}

// GoodUsage_Case1 should NOT trigger the rule
func GoodUsage_Case1(t *testing.T) {
  // Code that should NOT trigger the rule
  // OK: no issue here
}
```

### 3. Register in `ast-grep.yml`

```yaml
rules:
  - ./rules/NN-rule-name.yml
```

### 4. Test

```bash
make test
```

## Development Workflow

1. **Design the pattern** - Understand what code structure to detect
2. **Test the pattern** - Use `ast-grep run --pattern` to verify it matches
3. **Create rule file** - Write YAML rule with clear message
4. **Create test cases** - Write `BadUsage_*` and `GoodUsage_*` functions
5. **Register rule** - Add to `ast-grep.yml`
6. **Validate** - Run `make test` to ensure all cases work
7. **Lint** - Run `make lint` on real code to verify

## Debugging

### Pattern doesn't match?

Use ast-grep's debug output:
```bash
ast-grep run --pattern "your_pattern" test-file.go
```

### Inspect AST structure

Understand what the AST looks like for your code:
```bash
ast-grep run --pattern "for _ := range _ { $$_ }" file.go --debug-ast
```

Or use the MCP tool in Amp:
```
mcp__ast_grep__dump_syntax_tree(code="your code", language="go", format="cst")
```

## Key Principles

- **Pattern-driven**: All detection rules use AST patterns, not regex
- **Tested**: Every rule has comprehensive positive and negative test cases
- **Consistent**: All rules use `severity: warning` for uniform output
- **Documented**: Each rule has a clear, actionable message
- **Maintainable**: YAML-based rules are readable and easy to update

## Resources

- [AST-grep Documentation](https://ast-grep.github.io/)
- [AST-grep GitHub](https://github.com/ast-grep/ast-grep)
- [Model Context Protocol](https://modelcontextprotocol.io/)

