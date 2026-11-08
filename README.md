# Maid Suite

A lightweight TUI to **install, update, and check the whole Maidware toolset** from one place — the recommended unified front end (a clearer, all-in-one alternative to running tools/AU piecemeal).

Maid Suite is the canonical front end. It **embeds the Maid Helper and Maid AU updater cores** (self-contained in `libexec/`, GPL-3.0-or-later, behavior preserved) and **orchestrates** the other tools by fetching/running each tool’s **official** installer over HTTPS (URLs shown). It doesn’t store your data.

Part of the [Maidware Project](https://maidware-project.github.io/). Docs for the suite live on the [website guides](https://maidware-project.github.io/guides/).

## install

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/Maidware-Project/Maid-Suite/main/install.sh)
```

If a piped run behaves oddly on your shell:

```bash
curl -fsSL https://raw.githubusercontent.com/Maidware-Project/Maid-Suite/main/install.sh | bash
```

Check only (nothing changed): clone the repo and run `./install.sh --check`.

## usage

```bash
maid-suite
```

- **install/update all** (recommended) or **selected** tools: Maid AU, Maid Helper, Maid Runner, Maidshare, Maid BT
- **doctor/status**: what’s detected on your system (command markers)
- **easy navigation**: type a number and press Enter · `q` cancels/back

## safety

- Runs each tool’s official `install.sh` from `https://raw.githubusercontent.com/Maidware-Project/<repo>/main/install.sh` (downloaded to a temp file, shown before run).
- **No surprise sudo in non-interactive runs:** when Suite isn’t attached to a TTY it passes `--no-packages` to child installers; run a tool with `--packages` yourself if/when you want distro packages installed.
- Review scripts before running if you prefer (open the raw URL or clone the repo). Tools keep their own backups/`--check` behavior.

## license

GPL-3.0-or-later — forkable and open source. See `LICENSE`.
