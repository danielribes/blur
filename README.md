# blur

A CLI tool to anonymize CSV files. Zero external dependencies — just Bash and SQLite3.

## Why

CSV files often contain personal data (names, emails, phone numbers) that must be removed or masked before sharing, testing, or archiving. `blur` makes this a single command with no setup required.

## Requirements

- Bash (macOS ships with 3.2+, Linux with 4+)
- SQLite3 (pre-installed on macOS; available on all major Linux distros)

## Installation

```bash
git clone https://github.com/danielribes/blur.git
cd blur
chmod +x blur
```

Optionally add it to your PATH:

```bash
ln -s "$(pwd)/blur" /usr/local/bin/blur
```

## Usage

```bash
blur <file.csv> [options]
```

### Options

| Option | Description | Default |
|--------|-------------|---------|
| `-o <file>` | Output file path | `<name>_blur.csv` |
| `-c <col:method,...>` | Non-interactive: columns and methods to apply | — |
| `-s <sep>` | Force separator: `comma`, `semicolon`, `tab` (or `,` `;`) | auto-detect |
| `-p <n>` | Number of preview rows shown before selecting columns | `5` |
| `-h`, `--help` | Show help | — |

### Interactive mode

```bash
blur customers.csv
```

blur will show you the columns and a data preview, then ask which columns to anonymize and how.
You can select multiple columns at once:

```
Columns [1-6], or 'done': 2 4 5
  Method for 'full_name' [uuid/email/name/phone]: name
  Method for 'email' [uuid/email/name/phone]: email
  Method for 'phone' [uuid/email/name/phone]: phone
```

Or specify column and method together:

```
Columns [1-6], or 'done': 2:name 4:email 5:phone
```

### Non-interactive mode

```bash
blur customers.csv -c "email:email,full_name:name,phone:phone"
blur customers.csv -c "user_id:uuid" -o output.csv
blur customers.csv -c "email:email" -s semicolon -p 10
```

## Anonymization methods

| Method  | Example output             | Description                              |
|---------|----------------------------|------------------------------------------|
| `uuid`  | `a3f7c2d1...`              | Random 32-char hex string                |
| `email` | `a3f7c2d1...@anon.local`   | Random UUID-based address                |
| `name`  | `ANON_1`, `ANON_2`, ...    | Sequential anonymous identifiers         |
| `phone` | `63821049312`              | Random digits, same character length     |

## Principles

- **Non-destructive** — original files are never modified
- **No dependencies** — only SQLite3 and standard Unix utilities
- **Correct CSV parsing** — handles quoted fields, commas inside values
- **Transparent** — shows a preview before writing any output

## Running tests

```bash
bash tests/run_tests.sh
```

## License

MIT
