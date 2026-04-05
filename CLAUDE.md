# Blur — CLAUDE.md

> A CLI tool to anonymize CSV files using SQLite3. No dependencies required.

This file defines the coding standards and conventions for this project.
Claude Code must follow these rules in every file it generates or modifies.

---

## Stack

- **Bash** (POSIX compatible — must work on macOS and Linux)
- **SQLite3** (native, no installation required)
- Zero external dependencies

---

## Core Principles

- **Portability** — works on any Mac/Linux without installing anything
- **Non-destructive** — original files are never modified, always work on a copy
- **Simplicity** — one clear command per operation
- **Transparency** — always show the user what is about to happen before doing it

---

## Workflow

1. Import CSV into a temporary SQLite3 database
2. Show column names and preview first 5 rows (configurable with -p)
3. User selects columns to anonymize and method
4. Execute anonymization queries
5. Export anonymized data back to CSV
6. Clean up temporary database

---

## Anonymization Methods

- **uuid** — replace with random 32-char hex string
- **email** — replace with `<uuid>@anon.local`
- **phone** — replace with random digit sequence preserving length
- **name** — replace with `ANON_<sequential_number>`

---

## Code Style

- Meaningful variable names — no single letter variables except loop counters
- Every function must have a comment explaining its purpose
- Error handling — always check if SQLite3 is available, if file exists, if import succeeded
- Exit codes — 0 for success, 1 for user errors, 2 for system errors

---

## What to avoid

- Never modify the original CSV file
- No external tools beyond SQLite3 and standard Unix utilities (awk, sed, cut)
- No hardcoded paths
- No operations without user confirmation when destructive